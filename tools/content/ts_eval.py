"""A static evaluator for the pure-data subset of TypeScript, used to read World of
ClaudeCraft content at the pinned commit without running it.

Why it exists: many reference records are not literal text. Loot tables come from
helpers (`weightedLootGroup(...)`, `trashLoot(160, 'x')`), monsters from factories
(`hydraHead('mere_hydra_center', ...)`), and mechanics from shared constants
(`trashKit: BRINE_MEND_KIT`). A regex reads none of these, and silently missing them
breaks the fidelity rule (docs/REFERENCE_FIDELITY_RULE.md). This module parses the
source text and evaluates only side-effect-free constructs: literals, operators,
constants, spreads, and functions built from those, plus a fixed set of standard
built-ins (Array, Object, Math, Set, Map, String and Number methods).

Safety: nothing is executed by a JavaScript engine. The evaluator has no I/O of its
own: it reads modules only through the `read` callable it is given (the builder
passes `git show <pinned commit>:<path>`, which also hashes every input), it never
imports packages, and any construct outside the subset raises `Unsupported` with the
file, line and reason. Callers record that as UNKNOWN, never as a guess.

Values: numbers are Python floats (JavaScript numbers are IEEE doubles, so the
arithmetic is bit-identical), strings are str, arrays are list, plain objects are
dict (insertion order kept, as in JavaScript), `undefined` is UNDEF and `null` is
None. `to_json` converts a value for the registries.
"""

from __future__ import annotations

import bisect
import functools
import json
import math
import posixpath
import re
from typing import Any, Callable

# ---------------------------------------------------------------------------
# Values


class Unsupported(Exception):
    """A construct the evaluator does not model. Never guessed around."""

    def __init__(self, reason: str, where: str = "") -> None:
        super().__init__(f"{reason}" + (f" ({where})" if where else ""))
        self.reason = reason
        self.where = where


class _Undefined:
    _inst = None

    def __new__(cls):
        if cls._inst is None:
            cls._inst = super().__new__(cls)
        return cls._inst

    def __repr__(self) -> str:
        return "undefined"


UNDEF = _Undefined()


class Unknown:
    """A value the evaluator could not compute, kept in place inside a record so
    the rest of the record still evaluates. Serialised as {"$unknown": ...}."""

    def __init__(self, reason: str, where: str) -> None:
        self.reason = reason
        self.where = where


class ApproxFloat(float):
    """A number computed, directly or through later arithmetic, from an
    implementation-approximated operation. ECMAScript leaves Math.sin, cos, tan,
    asin, acos, atan, atan2, exp, log, log2, log10, cbrt, hypot, pow and the `**`
    operator to the engine, so the last bit may differ from V8. `sites` names
    every contributing call site ("file:line Math.op")."""

    sites: frozenset

    def __new__(cls, value, sites):
        obj = super().__new__(cls, value)
        obj.sites = frozenset(sites)
        return obj


class ApproxStr(str):
    """Text built from an ApproxFloat (string conversion or concatenation)."""

    sites: frozenset

    def __new__(cls, value, sites):
        obj = super().__new__(cls, value)
        obj.sites = frozenset(sites)
        return obj


# Math functions whose results ECMAScript leaves implementation-approximated.
APPROXIMATED_MATH = {"sin", "cos", "tan", "asin", "acos", "atan", "atan2", "exp", "log", "log2", "log10",
                     "cbrt", "hypot", "pow"}


def taint_of(*values) -> frozenset:
    out: frozenset = frozenset()
    for v in values:
        if isinstance(v, (ApproxFloat, ApproxStr)):
            out = out | v.sites
    return out


def tainted(value, sites):
    """Carry `sites` on a number or string result; other values are returned as is."""
    if not sites or isinstance(value, bool) or value is None:
        return value
    if isinstance(value, float):
        return ApproxFloat(value, sites)
    if isinstance(value, str):
        return ApproxStr(value, sites)
    return value


class Trace:
    """What the evaluator saw of approximated operations: every Math call (exact
    or approximated) with its site and enclosing function, and every decision
    (comparison, branch, key, index) taken on an approximated value. A decision is
    a possible implicit flow: the branch taken could depend on the last bit."""

    def __init__(self) -> None:
        self.calls: dict[tuple, int] = {}
        self.decisions: list[dict] = []
        self.stack: list[str] = []
        # Audit hook: maps (site, value) -> value for every approximated result,
        # used to perturb results by one ulp and compare the registries.
        self.perturb = None

    def context(self) -> str:
        return self.stack[-1] if self.stack else "<module top level>"

    def call(self, op: str, where: str, approximated: bool) -> None:
        key = (op, where, self.context(), approximated)
        self.calls[key] = self.calls.get(key, 0) + 1

    def decision(self, kind: str, sites: frozenset, where: str) -> None:
        bindings = [c[len("binding "):] for c in self.stack if c.startswith("binding ")]
        self.decisions.append({"kind": kind, "at": where, "context": " > ".join(self.stack[-4:]),
                               "binding": bindings[-1] if bindings else None, "sites": sorted(sites)})


TRACE: Trace | None = None


def note_decision(kind: str, sites: frozenset, where: str = "") -> None:
    if sites and TRACE is not None:
        TRACE.decision(kind, sites, where)


class JSSet:
    def __init__(self, items=()):
        self.items: list = []
        for it in items:
            self.add(it)

    def add(self, v):
        if not any(strict_eq(v, x) for x in self.items):
            self.items.append(v)
        return self

    def has(self, v) -> bool:
        return any(strict_eq(v, x) for x in self.items)


class JSMap:
    def __init__(self, pairs=()):
        self.pairs: list[list] = []
        for k, v in pairs:
            self.set(k, v)

    def _find(self, k):
        for p in self.pairs:
            if strict_eq(p[0], k):
                return p
        return None

    def set(self, k, v):
        p = self._find(k)
        if p:
            p[1] = v
        else:
            self.pairs.append([k, v])
        return self

    def get(self, k):
        p = self._find(k)
        return p[1] if p else UNDEF


class Closure:
    def __init__(self, name, params, body, scope, expr_body, interp, module, is_arrow=False, this_value=None):
        self.name = name
        self.params = params
        self.body = body
        self.scope = scope
        self.expr_body = expr_body
        self.interp = interp
        self.module = module
        # An arrow function takes `this` from where it was written; a method
        # carries the instance it was read from; any other function has none.
        self.is_arrow = is_arrow
        self.this_value = this_value

    def bound(self, this_value) -> "Closure":
        return Closure(self.name, self.params, self.body, self.scope, self.expr_body, self.interp, self.module,
                       False, this_value)

    def __call__(self, *args):
        return self.interp.call_closure(self, list(args))


class JSClass:
    """A class declaration: fields with initialisers, a constructor, methods and
    static members. Inheritance is not modelled (`extends` raises Unsupported)."""

    def __init__(self, name, members, extends, scope, interp, module, pos) -> None:
        self.name = name
        self.extends = extends
        self.scope = scope
        self.interp = interp
        self.module = module
        self.pos = pos
        self.fields: list = []
        self.methods: dict = {}
        self.ctor = None
        self.statics: dict = {}
        self.static_fields: list = []
        for m in members:
            kind = m[0]
            if kind == "field":
                (self.static_fields if m[3] else self.fields).append((m[1], m[2]))
            elif kind == "method":
                _, mname, params, body, static = m
                closure = Closure(mname, params, body, scope, False, interp, module)
                if static:
                    self.statics[mname] = closure
                elif mname == "constructor":
                    self.ctor = closure
                else:
                    self.methods[mname] = closure
            elif kind == "unsupported":
                target = self.statics if m[3] else self.methods
                target[m[1]] = Unknown(m[2], module.where(pos))
        self._statics_ready = False

    def static(self, key: str):
        if not self._statics_ready:
            self._statics_ready = True
            for fname, init in self.static_fields:
                self.statics[fname] = UNDEF if init is None else self.interp.eval(init, self.scope, self.module)
        if key in self.statics:
            v = self.statics[key]
            return v.bound(self) if isinstance(v, Closure) else v
        return UNDEF


class JSRegExp:
    """A regular expression literal, translated to Python `re` with JavaScript's
    semantics where they differ: `$` (without m) matches only at the very end,
    and \\d, \\w, \\s are ASCII. A construct Python cannot express the same way
    raises Unsupported."""

    def __init__(self, literal: str, where: str) -> None:
        body, _, flags = literal[1:].rpartition("/")
        self.source = body
        self.flags = flags
        if set(flags) - set("gimsuy") or "y" in flags:
            raise Unsupported(f"regular expression flags '{flags}'", where)
        out, i, in_class = [], 0, False
        while i < len(body):
            c = body[i]
            if c == "\\":
                nxt = body[i + 1:i + 2]
                if nxt in ("p", "P", "k", "c", "u", "x") and not (nxt in ("u", "x") and "u" not in flags and nxt == "u" and False):
                    if nxt in ("p", "P", "k", "c"):
                        raise Unsupported(f"regular expression escape \\{nxt}", where)
                out.append(body[i:i + 2])
                i += 2
                continue
            if in_class:
                if c == "]":
                    in_class = False
                out.append(c)
            elif c == "[":
                in_class = True
                out.append(c)
            elif c == "$" and "m" not in flags:
                out.append(r"\Z")
            elif c == "(" and body.startswith("(?<", i) and not body.startswith("(?<=", i) and not body.startswith("(?<!", i):
                out.append("(?P<")
                i += 3
                continue
            else:
                out.append(c)
            i += 1
        py_flags = re.ASCII
        if "i" in flags:
            py_flags |= re.IGNORECASE
        if "m" in flags:
            py_flags |= re.MULTILINE
        if "s" in flags:
            py_flags |= re.DOTALL
        try:
            self.pattern = re.compile("".join(out), py_flags)
        except re.error as e:
            raise Unsupported(f"regular expression /{body}/ ({e})", where) from None
        self.last_index = 0

    def exec(self, text: str):
        if "g" in self.flags:
            m = self.pattern.search(text, self.last_index)
            self.last_index = m.end() if m else 0
        else:
            m = self.pattern.search(text)
        if not m:
            return None
        return [m.group(0)] + [UNDEF if g is None else g for g in m.groups()]


class JSObject(dict):
    """An instance of a JSClass: own fields in the dict, methods on the class."""

    def __init__(self, jsclass: JSClass) -> None:
        super().__init__()
        self.jsclass = jsclass


class Builtin:
    def __init__(self, name: str, fn: Callable) -> None:
        self.name = name
        self.fn = fn

    def __call__(self, *args):
        if isinstance(self.fn, dict):
            call = self.fn.get("__call__")
            if call is None:
                raise Unsupported(f"'{self.name}' is not callable")
            return call(*args)
        return self.fn(*args)


def is_num(v) -> bool:
    return isinstance(v, float) and not isinstance(v, bool)


def strict_eq(a, b) -> bool:
    note_decision("equality", taint_of(a, b))
    if isinstance(a, bool) or isinstance(b, bool):
        return isinstance(a, bool) and isinstance(b, bool) and a == b
    if is_num(a) and is_num(b):
        return a == b
    if isinstance(a, str) and isinstance(b, str):
        return a == b
    if a is None or b is None or a is UNDEF or b is UNDEF:
        return a is b
    return a is b


def truthy(v) -> bool:
    note_decision("truthiness", taint_of(v))
    if isinstance(v, Unknown):
        raise Unsupported("truthiness of an unknown value", v.where)
    if v is None or v is UNDEF or v is False:
        return False
    if is_num(v):
        return not (v == 0 or math.isnan(v))
    if isinstance(v, str):
        return v != ""
    return True


def num_to_str(x: float) -> str:
    """ECMAScript Number::toString for a double."""
    if math.isnan(x):
        return "NaN"
    if math.isinf(x):
        return "Infinity" if x > 0 else "-Infinity"
    if x == 0:
        return "0"
    if x < 0:
        return "-" + num_to_str(-x)
    mant, _, exp = repr(x).partition("e")
    digits = mant.replace(".", "")
    point = mant.index(".") if "." in mant else len(mant)
    lead = len(digits) - len(digits.lstrip("0"))
    digits = digits.strip("0") or "0"
    n = point - lead + (int(exp) if exp else 0)
    k = len(digits)
    if k <= n <= 21:
        return digits + "0" * (n - k)
    if 0 < n <= 21:
        return digits[:n] + "." + digits[n:]
    if -6 < n <= 0:
        return "0." + "0" * (-n) + digits
    e = n - 1
    sign = "+" if e >= 0 else "-"
    head = digits[0] + ("." + digits[1:] if k > 1 else "")
    return f"{head}e{sign}{abs(e)}"


def to_str(v) -> str:
    if isinstance(v, (ApproxFloat, ApproxStr)):
        return ApproxStr(_to_str(v), v.sites)
    return _to_str(v)


def _to_str(v) -> str:
    if isinstance(v, str):
        return v
    if isinstance(v, bool):
        return "true" if v else "false"
    if is_num(v):
        return num_to_str(v)
    if v is None:
        return "null"
    if v is UNDEF:
        return "undefined"
    if isinstance(v, list):
        return ",".join("" if x is None or x is UNDEF else to_str(x) for x in v)
    raise Unsupported(f"string conversion of {type(v).__name__}")


def to_num(v) -> float:
    if is_num(v):
        return v
    if isinstance(v, bool):
        return 1.0 if v else 0.0
    if v is None:
        return 0.0
    if v is UNDEF:
        return math.nan
    if isinstance(v, str):
        s = v.strip()
        if s == "":
            return 0.0
        try:
            return float(s)
        except ValueError:
            return math.nan
    raise Unsupported(f"number conversion of {type(v).__name__}")


def to_int32(v) -> int:
    x = to_num(v)
    if math.isnan(x) or math.isinf(x):
        return 0
    i = int(x) & 0xFFFFFFFF
    return i - (1 << 32) if i >= (1 << 31) else i


def prop_key(v) -> str:
    note_decision("property key", taint_of(v))
    if isinstance(v, str):
        return v
    if is_num(v) or isinstance(v, bool) or v is None or v is UNDEF:
        return to_str(v)
    raise Unsupported("non-primitive property key")


def to_json(v, where: str = ""):
    """Registry form of a value. Undefined object fields are omitted, as
    JSON.stringify does; anything not plain data is marked, never dropped."""
    if isinstance(v, Unknown):
        return {"$unknown": v.reason, "at": v.where}
    if isinstance(v, (ApproxFloat, ApproxStr)):
        # Never presented as a verified value: the last bit is the engine's.
        return {"$unknown": "depends on an implementation-approximated operation",
                "at": sorted(v.sites)[0], "sites": sorted(v.sites),
                "value": str(v) if isinstance(v, str) else to_json(float(v))}
    if isinstance(v, bool) or v is None or isinstance(v, str):
        return v
    if is_num(v):
        if math.isnan(v) or math.isinf(v):
            return {"$number": num_to_str(v)}
        if v.is_integer() and abs(v) < 2**53:
            return int(v)
        return v
    if v is UNDEF:
        return None
    if isinstance(v, list):
        return [to_json(x, where) for x in v]
    if isinstance(v, dict):
        return {k: to_json(x, where) for k, x in v.items() if x is not UNDEF}
    if isinstance(v, JSSet):
        return {"$set": [to_json(x, where) for x in v.items]}
    if isinstance(v, JSMap):
        return {"$map": [[to_json(k, where), to_json(x, where)] for k, x in v.pairs]}
    if isinstance(v, Closure):
        return {"$function": v.name or "anonymous", "file": v.module.path}
    if isinstance(v, Builtin):
        return {"$function": v.name}
    if isinstance(v, Namespace):
        return {"$module": v.module.path}
    return {"$unknown": f"unserialisable {type(v).__name__}", "at": where}


# ---------------------------------------------------------------------------
# Lexer

PUNCT = sorted("""
>>>= ... === !== **= <<= >>= >>> &&= ||= ??= => == != <= >= && || ?? ?. ++ -- += -= *= /= %=
&= |= ^= ** << >> { } ( ) [ ] ; , < > + - * / % & | ^ ! ~ ? : = . @ #
""".split(), key=len, reverse=True)
KEYWORDS = {
    "break", "case", "catch", "class", "const", "continue", "debugger", "default", "delete", "do",
    "else", "export", "extends", "finally", "for", "function", "if", "import", "in", "instanceof",
    "let", "new", "return", "super", "switch", "this", "throw", "try", "typeof", "var", "void",
    "while", "with", "yield",
}
VALUE_END = {")", "]", "}"}
ID_START = re.compile(r"[A-Za-z_$\u0080-￿]")
ID_CHARS = re.compile(r"[A-Za-z0-9_$\u0080-￿]*")
NUM_RE = re.compile(
    r"0[xX][0-9a-fA-F_]+n?|0[bB][01_]+n?|0[oO][0-7_]+n?|(?:\d[\d_]*\.?[\d_]*|\.\d[\d_]*)(?:[eE][+-]?\d+)?n?"
)


class Tok:
    __slots__ = ("kind", "value", "pos", "nl")

    def __init__(self, kind, value, pos, nl):
        self.kind = kind
        self.value = value
        self.pos = pos
        self.nl = nl

    def is_(self, kind, value=None) -> bool:
        return self.kind == kind and (value is None or self.value == value)

    def __repr__(self) -> str:
        return f"{self.kind}:{self.value!r}@{self.pos}"


ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f", "v": "\v", "0": "\0"}


def lex(src: str, start: int = 0, stop_at_brace: bool = False) -> tuple[list[Tok], int]:
    """Tokens of src from start. With stop_at_brace, stops at the '}' that closes
    a template substitution and returns its index."""
    toks: list[Tok] = []
    i, n = start, len(src)
    nl = False
    depth = 0
    while i < n:
        c = src[i]
        if c in " \t\r﻿":
            i += 1
            continue
        if c == "\n":
            nl = True
            i += 1
            continue
        if src.startswith("//", i):
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if src.startswith("/*", i):
            j = src.find("*/", i + 2)
            if "\n" in src[i:j]:
                nl = True
            i = n if j < 0 else j + 2
            continue
        if c in "'\"":
            j = i + 1
            out = []
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j, ch = _escape(src, j)
                    out.append(ch)
                    continue
                out.append(src[j])
                j += 1
            toks.append(Tok("str", "".join(out), i, nl))
            i = j + 1
            nl = False
            continue
        if c == "`":
            parts, j = _template(src, i + 1)
            toks.append(Tok("tmpl", parts, i, nl))
            i = j
            nl = False
            continue
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            m = NUM_RE.match(src, i)
            text = m.group(0)
            if text.endswith("n") and not text.lower().startswith("0x"):
                toks.append(Tok("bigint", text, i, nl))
                i = m.end()
                nl = False
                continue
            t = text.replace("_", "")
            low = t.lower()
            if low.startswith("0x"):
                v = float(int(t[2:], 16))
            elif low.startswith("0b"):
                v = float(int(t[2:], 2))
            elif low.startswith("0o"):
                v = float(int(t[2:], 8))
            else:
                v = float(t)
            toks.append(Tok("num", v, i, nl))
            i = m.end()
            nl = False
            continue
        if ID_START.match(c) or c == "\\":
            m = ID_CHARS.match(src, i + 1)
            word = src[i:m.end()]
            toks.append(Tok("ident", word, i, nl))
            i = m.end()
            nl = False
            continue
        if c == "/" and _regex_allowed(toks):
            j = i + 1
            in_class = False
            while j < n:
                if src[j] == "\\":
                    j += 2
                    continue
                if src[j] == "[":
                    in_class = True
                elif src[j] == "]":
                    in_class = False
                elif src[j] == "/" and not in_class:
                    break
                elif src[j] == "\n":
                    break
                j += 1
            m = re.compile(r"[a-z]*").match(src, j + 1)
            toks.append(Tok("regex", src[i:m.end()], i, nl))
            i = m.end()
            nl = False
            continue
        for p in PUNCT:
            if src.startswith(p, i):
                if p == "?." and i + 2 < n and src[i + 2].isdigit():
                    p = "?"
                if stop_at_brace:
                    if p == "{":
                        depth += 1
                    elif p == "}":
                        if depth == 0:
                            return toks, i
                        depth -= 1
                toks.append(Tok("punct", p, i, nl))
                i += len(p)
                nl = False
                break
        else:
            raise Unsupported(f"unexpected character {c!r}", f"offset {i}")
    if stop_at_brace:
        raise Unsupported("unterminated template substitution", f"offset {start}")
    toks.append(Tok("eof", None, n, True))
    return toks, n


def _regex_allowed(toks: list[Tok]) -> bool:
    if not toks:
        return True
    t = toks[-1]
    if t.kind in ("num", "str", "tmpl", "regex", "bigint"):
        return False
    if t.kind == "ident":
        return t.value in KEYWORDS and t.value not in ("this", "super")
    return t.value not in VALUE_END


def _escape(src: str, j: int) -> tuple[int, str]:
    e = src[j + 1]
    if e in ESCAPES and not (e == "0" and src[j + 2:j + 3].isdigit()):
        return j + 2, ESCAPES[e]
    if e == "x":
        return j + 4, chr(int(src[j + 2:j + 4], 16))
    if e == "u":
        if src[j + 2] == "{":
            k = src.index("}", j)
            return k + 1, chr(int(src[j + 3:k], 16))
        return j + 6, chr(int(src[j + 2:j + 6], 16))
    if e == "\r" and src[j + 2:j + 3] == "\n":
        return j + 3, ""
    if e == "\n":
        return j + 2, ""
    return j + 2, e


def _template(src: str, i: int):
    parts: list = []
    buf: list[str] = []
    n = len(src)
    while i < n:
        c = src[i]
        if c == "`":
            parts.append("".join(buf))
            return parts, i + 1
        if c == "\\":
            i, ch = _escape(src, i)
            buf.append(ch)
            continue
        if src.startswith("${", i):
            parts.append("".join(buf))
            buf = []
            toks, end = lex(src, i + 2, stop_at_brace=True)
            toks.append(Tok("eof", None, end, False))
            parts.append(toks)
            i = end + 1
            continue
        buf.append(c)
        i += 1
    raise Unsupported("unterminated template literal")


# ---------------------------------------------------------------------------
# Parser. Nodes are tuples: (kind, pos, ...).

BINARY = {
    "??": 1, "||": 2, "&&": 3, "|": 4, "^": 5, "&": 6,
    "==": 7, "!=": 7, "===": 7, "!==": 7,
    "<": 8, ">": 8, "<=": 8, ">=": 8, "instanceof": 8, "in": 8,
    "<<": 9, ">>": 9, ">>>": 9, "+": 10, "-": 10, "*": 11, "/": 11, "%": 11, "**": 12,
}
ASSIGN = {"=", "+=", "-=", "*=", "/=", "%=", "**=", "<<=", ">>=", ">>>=", "&=", "|=", "^=", "&&=", "||=", "??="}
TYPE_STOP = {",", ")", "]", "}", ";", "=", "=>"}
AS_TYPE_STOP = {",", ")", "]", "}", ";", "=", "=>", "?", ":", "||", "&&", "??", "+", "-", "*", "/", "%",
                "==", "===", "!=", "!==", ">=", "<="}


class ParseError(Exception):
    pass


class Parser:
    def __init__(self, toks: list[Tok]) -> None:
        self.toks = toks
        self.i = 0

    # -- token helpers
    @property
    def t(self) -> Tok:
        return self.toks[self.i]

    def peek(self, k: int = 1) -> Tok:
        return self.toks[min(self.i + k, len(self.toks) - 1)]

    def at(self, value, kind="punct") -> bool:
        t = self.t
        return t.kind == kind and t.value == value

    def at_word(self, word) -> bool:
        return self.t.kind == "ident" and self.t.value == word

    def eat(self, value, kind="punct") -> bool:
        if self.at(value, kind):
            self.i += 1
            return True
        return False

    def expect(self, value, kind="punct") -> Tok:
        if not self.at(value, kind):
            raise ParseError(f"expected {value!r}, got {self.t!r}")
        t = self.t
        self.i += 1
        return t

    def ident(self) -> str:
        t = self.t
        if t.kind != "ident":
            raise ParseError(f"expected an identifier, got {t!r}")
        self.i += 1
        return t.value

    def semi(self) -> None:
        self.eat(";")

    # -- types are skipped, never evaluated
    def skip_type(self, stop=TYPE_STOP, stop_on_newline: bool = False) -> None:
        """Skip a type annotation. Types are never evaluated."""
        depth = 0
        start = self.i
        while True:
            t = self.t
            if t.kind == "eof":
                return
            if depth == 0 and self.i > start and stop_on_newline and t.nl and not (
                t.kind == "punct" and t.value in ("|", "&")
            ):
                return
            if t.kind == "punct":
                v = t.value
                prev_v = self.toks[self.i - 1].value if self.i > start else None
                opens_type = v in ("{", "(", "[") and (self.i == start or prev_v in ("|", "&"))
                if depth == 0 and v in stop and not opens_type:
                    # `(a: X) => Y` is a function type: its `=>` follows `)`.
                    prev = self.toks[self.i - 1]
                    if not (v == "=>" and prev.kind == "punct" and prev.value == ")" and self.i > start):
                        return
                if v in ("(", "[", "{", "<"):
                    depth += 1
                elif v in (")", "]", "}"):
                    if depth == 0:
                        return
                    depth -= 1
                elif v in (">", ">>", ">>>"):
                    depth -= len(v)
                    if depth < 0:
                        return
            self.i += 1

    def skip_balanced(self) -> None:
        """Skip from an opening bracket to its match."""
        open_ = self.t.value
        close = {"{": "}", "(": ")", "[": "]", "<": ">"}[open_]
        depth = 0
        while True:
            t = self.t
            if t.kind == "eof":
                raise ParseError("unbalanced")
            if t.kind == "punct":
                if t.value == open_:
                    depth += 1
                elif t.value == close or (open_ == "<" and t.value in (">>", ">>>")):
                    depth -= len(t.value) if open_ == "<" else 1
                    if depth <= 0:
                        self.i += 1
                        return
            self.i += 1

    def try_type_args(self) -> bool:
        """At '<' after a callee: skip generic arguments if they are followed by '('."""
        save = self.i
        depth = 0
        while True:
            t = self.t
            if t.kind == "eof" or (t.kind == "punct" and t.value in (";", "&&", "||", "{", "}")):
                self.i = save
                return False
            if t.kind == "punct":
                if t.value == "<":
                    depth += 1
                elif t.value in (">", ">>", ">>>"):
                    depth -= len(t.value)
                    if depth <= 0:
                        self.i += 1
                        if depth == 0 and self.at("("):
                            return True
                        self.i = save
                        return False
            self.i += 1

    # -- module
    def parse_module(self) -> list:
        body = []
        while self.t.kind != "eof":
            start = self.i
            try:
                st = self.statement(top=True)
            except (ParseError, Unsupported, IndexError) as e:
                self.i = start
                self.skip_statement()
                st = ("unparsed", self.toks[start].pos, str(e))
            if st is not None:
                body.append(st)
        return body

    def skip_statement(self) -> None:
        depth = 0
        first = True
        while self.t.kind != "eof":
            t = self.t
            if not first and depth == 0 and t.nl and t.kind == "ident" and t.value in (
                "export", "const", "let", "function", "import", "type", "interface", "class", "enum"
            ):
                return
            first = False
            if t.kind == "punct":
                if t.value in ("(", "[", "{"):
                    depth += 1
                elif t.value in (")", "]", "}"):
                    depth -= 1
                elif t.value == ";" and depth <= 0:
                    self.i += 1
                    return
            self.i += 1

    def statement(self, top: bool = False):
        t = self.t
        pos = t.pos
        if t.kind == "punct":
            if t.value == ";":
                self.i += 1
                return None
            if t.value == "{":
                return ("block", pos, self.block())
            if t.value == "@":
                raise Unsupported("decorator")
        if t.kind == "ident":
            w = t.value
            if w == "import" and not self.peek().is_("punct", "("):
                return self.import_decl()
            if w == "export":
                return self.export_decl()
            if w == "class":
                return self.class_decl()
            if w in ("class", "enum") or (w == "const" and self.peek().is_("ident", "enum")):
                if w == "const":
                    self.i += 1
                    w = "enum"
                name = self.peek().value
                self.i += 2
                while not self.at("{"):
                    self.i += 1
                self.skip_balanced()
                return ("unsupported_decl", pos, name, w)
            if w in ("const", "let", "var"):
                d = self.var_decl()
                self.semi()
                return d
            if w == "function" or (w == "async" and self.peek().is_("ident", "function")):
                return self.function_decl()
            if w in ("type",) and self.peek().kind == "ident" and not self.peek().nl:
                self.skip_type_decl()
                return None
            if w == "interface" or (w == "declare") or (w == "abstract" and self.peek().is_("ident", "class")):
                self.skip_type_decl()
                return None
            if w == "return":
                self.i += 1
                if self.at(";") or self.at("}") or self.t.nl:
                    self.semi()
                    return ("return", pos, None)
                e = self.expression()
                self.semi()
                return ("return", pos, e)
            if w == "if":
                self.i += 1
                self.expect("(")
                cond = self.expression()
                self.expect(")")
                then = self.statement()
                other = None
                if self.at_word("else"):
                    self.i += 1
                    other = self.statement()
                return ("if", pos, cond, then, other)
            if w == "throw":
                self.i += 1
                e = self.expression()
                self.semi()
                return ("throw", pos, e)
            if w == "for":
                return self.for_stmt()
            if w == "while":
                self.i += 1
                self.expect("(")
                cond = self.expression()
                self.expect(")")
                return ("while", pos, cond, self.statement())
            if w in ("break", "continue"):
                self.i += 1
                self.semi()
                return (w, pos)
            if w == "switch":
                return self.switch_stmt()
            if w in ("try", "do", "with"):
                raise Unsupported(f"'{w}' statement")
        e = self.expression()
        self.semi()
        return ("expr", pos, e)

    def switch_stmt(self):
        pos = self.t.pos
        self.i += 1
        self.expect("(")
        disc = self.expression()
        self.expect(")")
        self.expect("{")
        cases = []  # [(test expression, or None for default; statements)]
        while not self.at("}"):
            if self.at_word("case"):
                self.i += 1
                test = self.expression()
            elif self.at_word("default"):
                self.i += 1
                test = None
            else:
                raise ParseError("switch body without case")
            self.expect(":")
            body = []
            while not (self.at("}") or self.at_word("case") or self.at_word("default")):
                body.append(self.statement())
            cases.append((test, body))
        self.expect("}")
        return ("switch", pos, disc, cases)

    def class_decl(self):
        pos = self.t.pos
        self.expect("class", "ident")
        name = self.ident()
        if self.at("<"):
            self.skip_balanced()
        extends = None
        if self.at_word("extends"):
            self.i += 1
            extends = self.t.value
        while not self.at("{"):
            if self.t.kind == "eof":
                raise ParseError("class without a body")
            self.i += 1
        self.expect("{")
        members = []
        modifiers = {"public", "private", "protected", "readonly", "static", "override", "declare", "abstract", "accessor"}
        while not self.at("}"):
            if self.eat(";"):
                continue
            static = False
            while self.t.kind == "ident" and self.t.value in modifiers and not self.peek().is_("punct", "(") \
                    and not self.peek().is_("punct", ":") and not self.peek().is_("punct", "=") \
                    and not self.peek().is_("punct", ";") and not self.peek().is_("punct", "?"):
                static = static or self.t.value == "static"
                self.i += 1
            if self.at("["):  # an index signature or a computed member: types only here
                self.skip_balanced()
                if self.eat(":"):
                    self.skip_type(stop={";", "}"}, stop_on_newline=True)
                self.semi()
                continue
            if self.t.kind == "ident" and self.t.value in ("get", "set", "async") and self.peek().kind == "ident":
                word = self.t.value
                self.i += 1
                mname = self.prop_name()
                self.function_rest()
                members.append(("unsupported", mname, f"class '{word}' accessor or async method", static))
                continue
            if self.at("#"):
                raise Unsupported("private class field")
            mname = self.prop_name()
            self.eat("?")
            self.eat("!")
            if self.at("(") or self.at("<"):
                params, body = self.function_rest()
                if body is not None:
                    members.append(("method", mname, params, body, static))
                continue
            if self.eat(":"):
                self.skip_type(stop={"=", ";", "}"}, stop_on_newline=True)
            init = None
            if self.eat("="):
                init = self.assign()
            self.semi()
            members.append(("field", mname, init, static))
        self.expect("}")
        return ("class", pos, name, members, extends)

    def block(self) -> list:
        self.expect("{")
        body = []
        while not self.at("}"):
            if self.t.kind == "eof":
                raise ParseError("unterminated block")
            start = self.i
            try:
                st = self.statement()
            except (ParseError, Unsupported) as e:
                # Keep the enclosing function: only this statement is unknown,
                # and it raises if it is ever reached.
                self.i = start
                self.skip_inner_statement()
                st = ("unsupported_stmt", self.toks[start].pos, getattr(e, "reason", str(e)))
            if st is not None:
                body.append(st)
        self.expect("}")
        return body

    def skip_inner_statement(self) -> None:
        depth = 0
        while self.t.kind != "eof":
            t = self.t
            if t.kind == "punct":
                if t.value in ("(", "[", "{"):
                    depth += 1
                elif t.value in (")", "]", "}"):
                    if depth == 0:
                        return  # the enclosing block's own brace
                    depth -= 1
                    if depth == 0 and t.value == "}":
                        self.i += 1
                        if not (self.t.kind == "ident" and self.t.value in ("else", "catch", "finally", "while")):
                            self.eat(";")
                            return
                        continue
                elif t.value == ";" and depth == 0:
                    self.i += 1
                    return
            self.i += 1

    def skip_type_decl(self) -> None:
        """Skip `interface`, `type` and `declare` declarations: types only."""
        word = self.t.value
        if word == "declare" or word == "abstract":
            self.i += 1
            word = self.t.value
        if word in ("interface", "class", "global", "namespace", "module"):
            while not self.at("{"):
                if self.t.kind == "eof":
                    return
                self.i += 1
            self.skip_balanced()
            self.eat(";")
            return
        depth = 0
        while self.t.kind != "eof":
            t = self.t
            if t.kind == "punct":
                if t.value in ("(", "[", "{", "<"):
                    depth += 1
                elif t.value in (")", "]", "}"):
                    depth -= 1
                elif t.value in (">", ">>", ">>>"):
                    depth -= len(t.value)
                elif t.value == ";" and depth <= 0:
                    self.i += 1
                    return
            self.i += 1

    def import_decl(self):
        pos = self.t.pos
        self.expect("import", "ident")
        names = []  # (imported, local)
        if self.at_word("type") and not self.peek().is_("punct", ","):
            if not self.peek().is_("ident", "from"):
                self._skip_to_semi()
                return None
        if self.t.kind == "str":
            self.i += 1
            self.semi()
            return None
        if self.t.kind == "ident" and not self.at_word("from"):
            names.append(("default", self.ident()))
            self.eat(",")
        if self.eat("*"):
            self.expect("as", "ident")
            names.append(("*", self.ident()))
        if self.at("{"):
            self.i += 1
            while not self.at("}"):
                is_type = False
                if self.at_word("type") and self.peek().kind == "ident" and not self.peek().is_("ident", "as"):
                    is_type = True
                    self.i += 1
                imported = self.t.value
                self.i += 1
                local = imported
                if self.at_word("as"):
                    self.i += 1
                    local = self.ident()
                if not is_type:
                    names.append((imported, local))
                self.eat(",")
            self.expect("}")
        self.expect("from", "ident")
        spec = self.t.value
        self.i += 1
        self.semi()
        return ("import", pos, spec, names)

    def _skip_to_semi(self) -> None:
        while not self.at(";") and self.t.kind != "eof":
            self.i += 1
        self.semi()

    def export_decl(self):
        pos = self.t.pos
        self.expect("export", "ident")
        if self.at_word("default"):
            self.i += 1
            if self.at_word("function"):
                fn = self.function_decl()
                return ("export_default", pos, fn)
            e = self.expression()
            self.semi()
            return ("export_default", pos, e)
        if self.at_word("type") and self.peek().is_("punct", "{"):
            self._skip_to_semi()
            return None
        if self.at("*"):
            self.i += 1
            alias = None
            if self.at_word("as"):
                self.i += 1
                alias = self.ident()
            self.expect("from", "ident")
            spec = self.t.value
            self.i += 1
            self.semi()
            return ("export_star", pos, spec, alias)
        if self.at("{"):
            self.i += 1
            names = []
            while not self.at("}"):
                is_type = False
                if self.at_word("type") and self.peek().kind == "ident" and not self.peek().is_("ident", "as"):
                    is_type = True
                    self.i += 1
                local = self.t.value
                self.i += 1
                exported = local
                if self.at_word("as"):
                    self.i += 1
                    exported = self.t.value
                    self.i += 1
                if not is_type:
                    names.append((local, exported))
                self.eat(",")
            self.expect("}")
            spec = None
            if self.at_word("from"):
                self.i += 1
                spec = self.t.value
                self.i += 1
            self.semi()
            return ("export_names", pos, names, spec)
        st = self.statement(top=True)
        if st is None:
            return None
        return ("export", pos, st)

    def var_decl(self):
        pos = self.t.pos
        kind = self.ident()
        decls = []
        while True:
            target = self.pattern()
            if self.at("!"):
                self.i += 1
            if self.eat(":"):
                self.skip_type()
            init = None
            if self.eat("="):
                init = self.assign()
            decls.append((target, init))
            if not self.eat(","):
                break
        return ("var", pos, kind, decls)

    def pattern(self):
        pos = self.t.pos
        if self.at("["):
            self.i += 1
            elems = []
            while not self.at("]"):
                if self.at(","):
                    self.i += 1
                    elems.append(None)
                    continue
                if self.eat("..."):
                    elems.append(("rest", pos, self.pattern()))
                else:
                    p = self.pattern()
                    if self.eat("="):
                        p = ("default", pos, p, self.assign())
                    elems.append(p)
                if not self.at("]"):
                    self.expect(",")
            self.expect("]")
            return ("parr", pos, elems)
        if self.at("{"):
            self.i += 1
            props = []
            while not self.at("}"):
                if self.eat("..."):
                    props.append(("rest", self.pattern()))
                else:
                    if self.at("["):
                        self.i += 1
                        key = self.assign()
                        self.expect("]")
                    else:
                        key = ("str", pos, self.prop_name())
                    if self.eat(":"):
                        p = self.pattern()
                    else:
                        p = ("pid", pos, key[2])
                    if self.eat("="):
                        p = ("default", pos, p, self.assign())
                    props.append((key, p))
                if not self.at("}"):
                    self.expect(",")
            self.expect("}")
            return ("pobj", pos, props)
        return ("pid", pos, self.ident())

    def prop_name(self) -> str:
        t = self.t
        if t.kind in ("ident", "str"):
            self.i += 1
            return t.value
        if t.kind == "num":
            self.i += 1
            return num_to_str(t.value)
        raise ParseError(f"bad property name {t!r}")

    def function_decl(self):
        pos = self.t.pos
        if self.at_word("async"):
            raise Unsupported("async function")
        self.expect("function", "ident")
        if self.eat("*"):
            raise Unsupported("generator function")
        name = self.ident()
        params, body = self.function_rest()
        return ("function", pos, name, params, body)

    def function_rest(self):
        if self.at("<"):
            self.skip_balanced()
        params = self.params()
        if self.eat(":"):
            self.skip_type(stop={"{", ";"})
        if self.at("{"):
            body = self.block()
        else:
            self.semi()
            body = None  # an overload signature
        return params, body

    def params(self) -> list:
        self.expect("(")
        out = []
        while not self.at(")"):
            pos = self.t.pos
            while self.t.kind == "ident" and self.t.value in ("public", "private", "readonly", "protected") and self.peek().kind == "ident":
                self.i += 1
            rest = self.eat("...")
            if self.at_word("this") and self.peek().is_("punct", ":"):
                self.i += 2
                self.skip_type(stop={",", ")"})
                self.eat(",")
                continue
            p = self.pattern()
            self.eat("?")
            if self.eat(":"):
                self.skip_type(stop={",", ")", "="})
            default = None
            if self.eat("="):
                default = self.assign()
            out.append(("param", pos, p, default, rest))
            if not self.at(")"):
                self.expect(",")
        self.expect(")")
        return out

    def for_stmt(self):
        pos = self.t.pos
        self.expect("for", "ident")
        self.expect("(")
        if self.t.kind == "ident" and self.t.value in ("const", "let", "var"):
            save = self.i
            kind = self.ident()
            target = self.pattern()
            if self.at_word("of") or self.at_word("in"):
                which = self.ident()
                it = self.expression()
                self.expect(")")
                return ("for_" + which, pos, kind, target, it, self.statement())
            self.i = save
            init = self.var_decl()
        elif self.at(";"):
            init = None
        else:
            init = ("expr", pos, self.expression())
        self.expect(";")
        cond = None if self.at(";") else self.expression()
        self.expect(";")
        update = None if self.at(")") else self.expression()
        self.expect(")")
        return ("for", pos, init, cond, update, self.statement())

    # -- expressions
    def expression(self):
        e = self.assign()
        if self.at(","):
            items = [e]
            while self.eat(","):
                items.append(self.assign())
            return ("seq", e[1], items)
        return e

    def assign(self):
        t = self.t
        pos = t.pos
        if t.kind == "ident" and t.value == "async" and (self.peek().is_("punct", "(") or self.peek().kind == "ident") \
                and not self.peek().nl:
            self.i += 1
            self.assign()
            return ("unsupported", pos, "async function")
        if t.kind == "ident" and t.value not in KEYWORDS and self.peek().is_("punct", "=>"):
            name = self.ident()
            self.expect("=>")
            return self.arrow_body(pos, [("param", pos, ("pid", pos, name), None, False)])
        if t.kind == "punct" and t.value in ("(", "<"):
            arrow = self.try_arrow()
            if arrow is not None:
                return arrow
        if t.kind == "ident" and t.value == "yield":
            raise Unsupported("yield")
        left = self.conditional()
        if self.t.kind == "punct" and self.t.value in ASSIGN:
            op = self.t.value
            self.i += 1
            right = self.assign()
            return ("assign", pos, op, left, right)
        return left

    def try_arrow(self):
        save = self.i
        pos = self.t.pos
        try:
            if self.at("<"):
                self.skip_balanced()
            params = self.params()
            if self.eat(":"):
                self.skip_type(stop={"=>"})
            if not self.at("=>"):
                raise ParseError("not an arrow")
            self.i += 1
        except (ParseError, Unsupported, IndexError):
            self.i = save
            return None
        return self.arrow_body(pos, params)

    def arrow_body(self, pos, params):
        if self.at("{"):
            return ("arrow", pos, params, self.block(), False)
        return ("arrow", pos, params, self.assign(), True)

    def conditional(self):
        pos = self.t.pos
        cond = self.binary(0)
        if self.at("?"):
            self.i += 1
            a = self.assign()
            self.expect(":")
            b = self.assign()
            return ("cond", pos, cond, a, b)
        return cond

    def binary(self, min_prec: int):
        left = self.unary()
        while True:
            t = self.t
            if t.kind == "ident" and t.value in ("as", "satisfies") and not t.nl:
                self.i += 1
                if self.at_word("const"):
                    self.i += 1
                else:
                    self.skip_type(stop=AS_TYPE_STOP, stop_on_newline=True)
                continue
            op = t.value if t.kind == "punct" or (t.kind == "ident" and t.value in ("instanceof", "in")) else None
            prec = BINARY.get(op) if op is not None else None
            if prec is None or prec < min_prec:
                return left
            self.i += 1
            # `**` is right-associative; everything else is left-associative.
            right = self.binary(prec if op == "**" else prec + 1)
            left = ("bin", t.pos, op, left, right)

    def unary(self):
        t = self.t
        pos = t.pos
        if t.kind == "punct" and t.value in ("!", "-", "+", "~"):
            self.i += 1
            return ("unary", pos, t.value, self.unary())
        if t.kind == "punct" and t.value in ("++", "--"):
            self.i += 1
            return ("update", pos, t.value, True, self.unary())
        if t.kind == "ident" and t.value in ("typeof", "void", "delete", "await"):
            self.i += 1
            operand = self.unary()
            if t.value in ("delete", "await"):
                return ("unsupported", pos, f"'{t.value}'")
            return ("unary", pos, t.value, operand)
        if t.kind == "punct" and t.value == "<":
            raise Unsupported("angle-bracket type assertion")
        e = self.postfix()
        if self.t.kind == "punct" and self.t.value in ("++", "--") and not self.t.nl:
            op = self.t.value
            self.i += 1
            return ("update", pos, op, False, e)
        return e

    def postfix(self):
        start = self.t.pos
        e = self._postfix()
        # An optional link short-circuits the WHOLE chain (`a?.b.c` is undefined
        # when a is nullish), so the chain is one node that catches the signal.
        return ("chain", start, e) if self._optional_in(e) else e

    @staticmethod
    def _optional_in(e) -> bool:
        while isinstance(e, tuple) and e and e[0] in ("member", "call"):
            if e[4]:
                return True
            e = e[2]
        return False

    def _postfix(self):
        e = self.primary()
        while True:
            t = self.t
            if t.kind != "punct":
                if t.kind == "tmpl":
                    raise Unsupported("tagged template")
                return e
            v = t.value
            if v == ".":
                self.i += 1
                if self.at("#"):
                    raise Unsupported("private field")
                name = self.t.value
                self.i += 1
                e = ("member", t.pos, e, ("str", t.pos, name), False)
            elif v == "?.":
                self.i += 1
                if self.at("("):
                    e = ("call", t.pos, e, self.args(), True)
                elif self.at("["):
                    self.i += 1
                    k = self.expression()
                    self.expect("]")
                    e = ("member", t.pos, e, k, True)
                else:
                    name = self.t.value
                    self.i += 1
                    e = ("member", t.pos, e, ("str", t.pos, name), True)
            elif v == "[" and not t.nl:
                self.i += 1
                k = self.expression()
                self.expect("]")
                e = ("member", t.pos, e, k, False)
            elif v == "(" and not (t.nl and e[0] == "arrow"):
                e = ("call", t.pos, e, self.args(), False)
            elif v == "!" and not t.nl and not self.peek().is_("punct", "="):
                self.i += 1  # non-null assertion
            elif v == "<" and e[0] in ("id", "member") and self.try_type_args():
                continue
            else:
                return e

    def args(self) -> list:
        self.expect("(")
        out = []
        while not self.at(")"):
            if self.eat("..."):
                out.append(("spread", self.t.pos, self.assign()))
            else:
                out.append(self.assign())
            if not self.at(")"):
                self.expect(",")
        self.expect(")")
        return out

    def primary(self):
        t = self.t
        pos = t.pos
        k = t.kind
        if k == "num":
            self.i += 1
            return ("num", pos, t.value)
        if k == "str":
            self.i += 1
            return ("str", pos, t.value)
        if k == "tmpl":
            self.i += 1
            parts = []
            for p in t.value:
                if isinstance(p, str):
                    parts.append(p)
                else:
                    sub = Parser(p)
                    parts.append(sub.expression())
            return ("tmpl", pos, parts)
        if k == "regex":
            self.i += 1
            return ("regex", pos, t.value)
        if k == "bigint":
            self.i += 1
            return ("unsupported", pos, "bigint literal")
        if k == "punct":
            v = t.value
            if v == "(":
                self.i += 1
                e = self.expression()
                self.expect(")")
                return ("paren", pos, e)
            if v == "[":
                return self.array_lit()
            if v == "{":
                return self.object_lit()
            raise ParseError(f"unexpected {t!r}")
        if k == "ident":
            w = t.value
            if w == "true" or w == "false":
                self.i += 1
                return ("bool", pos, w == "true")
            if w == "null":
                self.i += 1
                return ("null", pos)
            if w == "undefined":
                self.i += 1
                return ("undef", pos)
            if w == "function":
                self.i += 1
                if self.eat("*"):
                    raise Unsupported("generator function")
                name = self.ident() if self.t.kind == "ident" else None
                params, body = self.function_rest()
                return ("fnexpr", pos, name, params, body)
            if w == "new":
                self.i += 1
                callee = self.primary()
                while self.at("."):
                    self.i += 1
                    callee = ("member", pos, callee, ("str", pos, self.t.value), False)
                    self.i += 1
                if self.at("<"):
                    self.skip_balanced()
                a = self.args() if self.at("(") else []
                return ("new", pos, callee, a)
            if w == "this":
                self.i += 1
                return ("this", pos)
            if w == "super":
                self.i += 1
                return ("unsupported", pos, "'super'")
            if w == "import":
                self.i += 1
                if self.at("("):
                    self.args()
                elif self.eat("."):
                    self.i += 1
                return ("unsupported", pos, "dynamic import or import.meta")
            if w == "class":
                raise Unsupported("class expression")
            self.i += 1
            return ("id", pos, w)
        raise ParseError(f"unexpected {t!r}")

    def array_lit(self):
        pos = self.t.pos
        self.expect("[")
        items = []
        while not self.at("]"):
            if self.at(","):
                self.i += 1
                items.append(("hole", pos))
                continue
            if self.eat("..."):
                items.append(("spread", self.t.pos, self.assign()))
            else:
                items.append(self.assign())
            if not self.at("]"):
                self.expect(",")
        self.expect("]")
        return ("array", pos, items)

    def object_lit(self):
        pos = self.t.pos
        self.expect("{")
        props = []
        while not self.at("}"):
            ppos = self.t.pos
            if self.eat("..."):
                props.append(("spread", ppos, self.assign()))
            else:
                if self.t.kind == "ident" and self.t.value in ("get", "set", "async") and not self.peek().is_("punct", ":") \
                        and not self.peek().is_("punct", ",") and not self.peek().is_("punct", "(") and not self.peek().is_("punct", "}"):
                    word = self.t.value
                    self.i += 1
                    name = self.prop_name() if not self.at("[") else None
                    if name is None:
                        self.skip_balanced()
                    self.function_rest()
                    props.append(("prop", ppos, ("str", ppos, name or "$computed"), ("unsupported", ppos, f"object '{word}' accessor or async method")))
                    if not self.at("}"):
                        self.expect(",")
                    continue
                if self.at("["):
                    self.i += 1
                    key = self.assign()
                    self.expect("]")
                    shorthand = None
                else:
                    tk = self.t
                    name = self.prop_name()
                    key = ("str", ppos, name)
                    shorthand = name if tk.kind == "ident" else None
                if self.at("(") or self.at("<"):
                    params, body = self.function_rest()
                    props.append(("prop", ppos, key, ("fnexpr", ppos, key[2] if key[0] == "str" else None, params, body)))
                elif self.eat(":"):
                    props.append(("prop", ppos, key, self.assign()))
                elif shorthand is not None:
                    props.append(("prop", ppos, key, ("id", ppos, shorthand)))
                else:
                    raise ParseError("bad object property")
            if not self.at("}"):
                self.expect(",")
        self.expect("}")
        return ("object", pos, props)


# ---------------------------------------------------------------------------
# Interpreter


class _Return(Exception):
    def __init__(self, value):
        self.value = value


class _Break(Exception):
    pass


class _Continue(Exception):
    pass


class _Throw(Exception):
    pass


class Scope:
    def __init__(self, parent: Scope | None = None) -> None:
        self.vars: dict[str, Any] = {}
        self.parent = parent
        self.mutable: set[str] = set()  # module-level `let`/`var` names

    def lookup(self, name: str):
        s = self
        while s is not None:
            if name in s.vars:
                return s, s.vars[name]
            s = s.parent
        return None, None

    def assign(self, name: str, value) -> None:
        s, _ = self.lookup(name)
        if s is None:
            raise Unsupported(f"assignment to undeclared '{name}'")
        s.vars[name] = value


class _Lazy:
    """A module-level binding, evaluated on first use."""

    def __init__(self, thunk: Callable[[], Any], name: str, owner: str = "") -> None:
        self.thunk = thunk
        self.name = name
        self.owner = owner  # the defining module, for the trace
        self.state = 0  # 0 not evaluated, 1 evaluating, 2 done
        self.value: Any = None
        self.error: Unsupported | None = None

    def get(self):
        if self.state == 2:
            if self.error:
                raise self.error
            return self.value
        if self.state == 1:
            raise Unsupported(f"circular initialisation of '{self.name}'")
        self.state = 1
        if TRACE is not None:
            TRACE.stack.append(f"binding {self.owner}#{self.name}" if self.owner else f"binding {self.name}")
        try:
            self.value = self.thunk()
        except Unsupported as e:
            self.error = e
            self.state = 2
            raise
        except _Throw as e:
            self.error = Unsupported(f"the source throws while building '{self.name}': {e}")
            self.state = 2
            raise self.error from None
        except RecursionError:
            self.error = Unsupported(f"recursion too deep building '{self.name}'")
            self.state = 2
            raise self.error from None
        finally:
            if TRACE is not None:
                TRACE.stack.pop()
        self.state = 2
        return self.value


class Namespace:
    def __init__(self, module: "Module") -> None:
        self.module = module


class Module:
    def __init__(self, interp: "Interpreter", path: str, text: str) -> None:
        self.interp = interp
        self.path = path
        self.text = text
        self.lines = [m.start() for m in re.finditer("\n", text)]
        toks, _ = lex(text)
        self.body = Parser(toks).parse_module()
        self.scope = Scope(interp.globals)
        self.exports: dict[str, Callable[[], Any]] = {}
        self.stars: list[str] = []
        # Top-level statements that are not declarations, e.g. a loop that adds
        # records to an exported table. They run once, in source order, when the
        # module loads (Interpreter.module_for), as an ES module's body does.
        self.effects: list[str] = []
        self.effect_nodes: list[tuple] = []
        self.effect_results: list[tuple[str, str]] = []
        self.unparsed: list[str] = []
        self.decl_nodes: dict[str, tuple] = {}
        for st in self.body:
            self._declare(st)

    def where(self, pos: int) -> str:
        return f"{self.path}:{bisect.bisect_right(self.lines, pos - 1) + 1}"

    def _declare(self, st, exported: bool = False) -> None:
        kind = st[0]
        if kind == "import":
            _, pos, spec, names = st
            for imported, local in names:
                self.scope.vars[local] = _Lazy(functools.partial(self._import, spec, imported, pos), local)
        elif kind == "export":
            inner = st[2]
            self._declare(inner, exported=True)
        elif kind == "var":
            _, pos, vkind, decls = st
            for target, init in decls:
                names = pattern_names(target)
                if vkind != "const":
                    self.scope.mutable.update(names)
                if target[0] == "pid":
                    self.decl_nodes[target[2]] = init
                    lazy = _Lazy(functools.partial(self._eval_init, init, pos), target[2], self.path)
                    self.scope.vars[target[2]] = lazy
                else:
                    holder = _Lazy(functools.partial(self._eval_init, init, pos), "+".join(names))
                    for nm in names:
                        self.scope.vars[nm] = _Lazy(functools.partial(self._destructured, target, holder, nm, pos), nm)
                if exported:
                    for nm in names:
                        self.exports[nm] = functools.partial(self._get_local, nm)
        elif kind == "function":
            _, pos, name, params, body = st
            if body is None:
                return
            self.scope.vars[name] = Closure(name, params, body, self.scope, False, self.interp, self)
            if exported:
                self.exports[name] = functools.partial(self._get_local, name)
        elif kind == "class":
            _, pos, name, members, extends = st
            self.scope.vars[name] = JSClass(name, members, extends, self.scope, self.interp, self, pos)
            if exported:
                self.exports[name] = functools.partial(self._get_local, name)
        elif kind == "unsupported_decl":
            _, pos, name, w = st
            err = Unsupported(f"'{w}' declaration '{name}'", self.where(pos))
            self.scope.vars[name] = _Lazy(functools.partial(_raise, err), name)
            if exported:
                self.exports[name] = functools.partial(self._get_local, name)
        elif kind == "export_names":
            _, pos, names, spec = st
            for local, exported_name in names:
                if spec is None:
                    self.exports[exported_name] = functools.partial(self._get_local, local)
                else:
                    self.exports[exported_name] = functools.partial(self._import_value, spec, local, pos)
        elif kind == "export_star":
            _, pos, spec, alias = st
            if alias:
                self.exports[alias] = functools.partial(self._namespace, spec, pos)
            else:
                self.stars.append(spec)
        elif kind == "export_default":
            node = st[2]
            if node[0] == "function":
                self._declare(node)
                self.exports["default"] = functools.partial(self._get_local, node[2])
            else:
                lazy = _Lazy(functools.partial(self._eval_init, node, st[1]), "default")
                self.exports["default"] = lazy.get
        elif kind == "unparsed":
            self.unparsed.append(f"{self.where(st[1])}: {st[2]}")
        elif kind in ("expr", "if", "for", "for_of", "for_in", "while", "block", "throw", "return", "switch"):
            self.effects.append(self.where(st[1]))
            self.effect_nodes.append(st)

    def run_effects(self) -> None:
        for st in self.effect_nodes:
            where = self.where(st[1])
            if TRACE is not None:
                TRACE.stack.append(f"top-level statement {where}")
            try:
                self.interp.exec(st, self.scope, self)
                self.effect_results.append((where, "applied"))
            except Unsupported as e:
                self.effect_results.append((where, f"UNKNOWN: {e.reason}" + (f" ({e.where})" if e.where else "")))
            except (_Throw, _Return, _Break, _Continue, RecursionError) as e:
                self.effect_results.append((where, f"UNKNOWN: {type(e).__name__.strip('_').lower()} at top level"))
            finally:
                if TRACE is not None:
                    TRACE.stack.pop()

    def _eval_init(self, init, pos):
        if init is None:
            return UNDEF
        return self.interp.eval(init, self.scope, self)

    def _destructured(self, target, holder: _Lazy, name: str, pos):
        tmp = Scope(None)
        self.interp.bind_pattern(target, holder.get(), tmp, self)
        return tmp.vars[name]

    def _get_local(self, name: str):
        v = self.scope.vars.get(name, UNDEF)
        return v.get() if isinstance(v, _Lazy) else v

    def _import(self, spec: str, imported: str, pos: int):
        if imported == "*":
            return self._namespace(spec, pos)
        return self._import_value(spec, imported, pos)

    def _namespace(self, spec: str, pos: int):
        return Namespace(self.interp.module_for(self.resolve(spec, pos)))

    def _import_value(self, spec: str, name: str, pos: int):
        path = self.resolve(spec, pos)
        if path.endswith(".json"):
            data = self.interp.json_module(path)
            if name == "default":
                return data
            return data[name]
        return self.interp.module_for(path).export(name)

    def resolve(self, spec: str, pos: int) -> str:
        if not spec.startswith("."):
            raise Unsupported(f"package import '{spec}'", self.where(pos))
        base = posixpath.normpath(posixpath.join(posixpath.dirname(self.path), spec))
        cands = [base, base + ".ts", base + "/index.ts"]
        if base.endswith(".js"):
            cands.insert(0, base[:-3] + ".ts")
        for c in cands:
            if self.interp.exists(c):
                return c
        raise Unsupported(f"module '{spec}' not found", self.where(pos))

    def override(self, name: str, value) -> None:
        """Replace one module-scope binding (a side-effecting collaborator) for a
        verification run. The function under test stays the source's own."""
        if name not in self.scope.vars:
            raise Unsupported(f"no binding '{name}' in {self.path} to override")
        self.scope.vars[name] = value

    def export(self, name: str):
        if name in self.exports:
            return self.exports[name]()
        for spec in self.stars:
            mod = self.interp.module_for(self.resolve(spec, 0))
            if mod.has_export(name):
                return mod.export(name)
        raise Unsupported(f"'{name}' is not exported by {self.path}")

    def has_export(self, name: str) -> bool:
        if name in self.exports:
            return True
        return any(self.interp.module_for(self.resolve(s, 0)).has_export(name) for s in self.stars)

    def origin(self, name: str) -> tuple[str, str]:
        """(file, local name) where an imported or local binding is defined."""
        for st in self.body:
            if st[0] == "import":
                for imported, local in st[3]:
                    if local == name and imported != "*":
                        mod = self.interp.module_for(self.resolve(st[2], st[1]))
                        return mod.export_origin(imported)
        return self.path, name

    def export_origin(self, name: str) -> tuple[str, str]:
        for st in self.body:
            if st[0] == "export_names":
                for local, exported in st[2]:
                    if exported == name:
                        if st[3] is None:
                            return self.origin(local)
                        return self.interp.module_for(self.resolve(st[3], st[1])).export_origin(local)
        if name in self.exports:
            return self.origin(name)
        for spec in self.stars:
            mod = self.interp.module_for(self.resolve(spec, 0))
            if mod.has_export(name):
                return mod.export_origin(name)
        raise Unsupported(f"'{name}' is not exported by {self.path}")


def _raise(err):
    raise err


def pattern_names(p) -> list[str]:
    if p is None:
        return []
    k = p[0]
    if k == "pid":
        return [p[2]]
    if k == "default":
        return pattern_names(p[2])
    if k == "rest":
        return pattern_names(p[2])
    if k == "parr":
        return [n for e in p[2] if e is not None for n in pattern_names(e)]
    if k == "pobj":
        out = []
        for item in p[2]:
            out += pattern_names(item[1])
        return out
    return []


class Interpreter:
    """Evaluates modules read through `read(path) -> text`; `exists(path)` says
    whether a path is a file at the pinned commit."""

    MAX_STEPS = 50_000_000

    def __init__(self, read: Callable[[str], str], exists: Callable[[str], bool]) -> None:
        self.read = read
        self.exists = exists
        self.modules: dict[str, Module] = {}
        self.jsons: dict[str, Any] = {}
        self.steps = 0
        self.globals = Scope(None)
        self.globals.vars.update(make_globals(self))

    def module_for(self, path: str) -> Module:
        if path not in self.modules:
            mod = Module(self, path, self.read(path))
            self.modules[path] = mod
            mod.run_effects()
        return self.modules[path]

    def json_module(self, path: str):
        if path not in self.jsons:
            self.jsons[path] = from_json(json.loads(self.read(path)))
        return self.jsons[path]

    # -- statements
    def exec_block(self, body: list, scope: Scope, mod: Module) -> None:
        for st in body:
            if st[0] == "function" and st[4] is not None:
                scope.vars[st[2]] = Closure(st[2], st[3], st[4], scope, False, self, mod)
        for st in body:
            self.exec(st, scope, mod)

    def exec(self, st, scope: Scope, mod: Module) -> None:
        self.steps += 1
        if self.steps > self.MAX_STEPS:
            raise Unsupported("evaluation step budget exhausted", mod.where(st[1]))
        k = st[0]
        if k == "expr":
            self.eval(st[2], scope, mod)
        elif k == "var":
            for target, init in st[3]:
                v = UNDEF if init is None else self.eval(init, scope, mod)
                self.bind_pattern(target, v, scope, mod)
        elif k == "return":
            raise _Return(UNDEF if st[2] is None else self.eval(st[2], scope, mod))
        elif k == "if":
            if truthy(self.eval(st[2], scope, mod)):
                self.exec(st[3], scope, mod)
            elif st[4] is not None:
                self.exec(st[4], scope, mod)
        elif k == "block":
            self.exec_block(st[2], Scope(scope), mod)
        elif k == "throw":
            raise _Throw(f"{mod.where(st[1])}")
        elif k == "function":
            pass
        elif k == "for_of":
            it = self.iterate(self.eval(st[4], scope, mod), mod.where(st[1]))
            for v in it:
                inner = Scope(scope)
                self.bind_pattern(st[3], v, inner, mod)
                try:
                    self.exec(st[5], inner, mod)
                except _Break:
                    break
                except _Continue:
                    continue
        elif k == "for_in":
            obj = self.eval(st[4], scope, mod)
            if not isinstance(obj, dict):
                raise Unsupported("for-in over a non-object", mod.where(st[1]))
            for key in list(obj.keys()):
                inner = Scope(scope)
                self.bind_pattern(st[3], key, inner, mod)
                try:
                    self.exec(st[5], inner, mod)
                except _Break:
                    break
                except _Continue:
                    continue
        elif k == "for":
            loop = Scope(scope)
            if st[2] is not None:
                self.exec(st[2], loop, mod)
            while st[3] is None or truthy(self.eval(st[3], loop, mod)):
                self.steps += 1
                if self.steps > self.MAX_STEPS:
                    raise Unsupported("evaluation step budget exhausted", mod.where(st[1]))
                body_scope = Scope(loop)
                try:
                    self.exec(st[5], body_scope, mod)
                except _Break:
                    break
                except _Continue:
                    pass
                if st[4] is not None:
                    self.eval(st[4], loop, mod)
        elif k == "while":
            while truthy(self.eval(st[2], scope, mod)):
                self.steps += 1
                if self.steps > self.MAX_STEPS:
                    raise Unsupported("evaluation step budget exhausted", mod.where(st[1]))
                try:
                    self.exec(st[3], Scope(scope), mod)
                except _Break:
                    break
                except _Continue:
                    continue
        elif k == "switch":
            # JavaScript semantics: strict equality in order, fall-through until a
            # break, default taken when no case matches (wherever it is written).
            disc = self.eval(st[2], scope, mod)
            where = mod.where(st[1])
            start = None
            for i, (test, _) in enumerate(st[3]):
                if test is not None and truthy(binop("===", disc, self.eval(test, scope, mod), where)):
                    start = i
                    break
            if start is None:
                start = next((i for i, (test, _) in enumerate(st[3]) if test is None), None)
            if start is not None:
                inner = Scope(scope)
                body = [x for _, stmts in st[3][start:] for x in stmts]
                try:
                    self.exec_block(body, inner, mod)
                except _Break:
                    pass
        elif k == "break":
            raise _Break()
        elif k == "continue":
            raise _Continue()
        elif k == "unsupported_decl":
            raise Unsupported(f"'{st[3]}' declaration", mod.where(st[1]))
        elif k == "unsupported_stmt":
            raise Unsupported(st[2], mod.where(st[1]))
        elif k in ("import", "export", "export_names", "export_star", "export_default"):
            raise Unsupported("module declaration inside a function", mod.where(st[1]))
        else:
            raise Unsupported(f"statement '{k}'", mod.where(st[1]))

    def bind_pattern(self, p, value, scope: Scope, mod: Module) -> None:
        k = p[0]
        if k == "pid":
            scope.vars[p[2]] = value
        elif k == "default":
            self.bind_pattern(p[2], self.eval(p[3], scope, mod) if value is UNDEF else value, scope, mod)
        elif k == "parr":
            items = self.iterate(value, mod.where(p[1]))
            for idx, e in enumerate(p[2]):
                if e is None:
                    continue
                if e[0] == "rest":
                    self.bind_pattern(e[2], list(items[idx:]), scope, mod)
                    break
                self.bind_pattern(e, items[idx] if idx < len(items) else UNDEF, scope, mod)
        elif k == "pobj":
            used = []
            for item in p[2]:
                if item[0] == "rest":
                    if not isinstance(value, dict):
                        raise Unsupported("object rest from a non-object", mod.where(p[1]))
                    self.bind_pattern(item[1], {kk: vv for kk, vv in value.items() if kk not in used}, scope, mod)
                    continue
                key = prop_key(self.eval(item[0], scope, mod))
                used.append(key)
                self.bind_pattern(item[1], self.get(value, key, mod.where(p[1])), scope, mod)
        else:
            raise Unsupported(f"pattern '{k}'", mod.where(p[1]))

    def call_closure(self, fn: Closure, args: list):
        if TRACE is None:
            return self._call_closure(fn, args)
        TRACE.stack.append(f"{fn.module.path} {fn.name or 'anonymous'}()")
        try:
            return self._call_closure(fn, args)
        finally:
            TRACE.stack.pop()

    def _call_closure(self, fn: Closure, args: list):
        scope = Scope(fn.scope)
        if not fn.is_arrow:
            scope.vars["%this"] = UNDEF if fn.this_value is None else fn.this_value
        mod = fn.module
        for idx, prm in enumerate(fn.params):
            _, pos, pat, default, rest = prm
            if rest:
                self.bind_pattern(pat, args[idx:], scope, mod)
                break
            v = args[idx] if idx < len(args) else UNDEF
            if v is UNDEF and default is not None:
                v = self.eval(default, scope, mod)
            self.bind_pattern(pat, v, scope, mod)
        if fn.expr_body:
            return self.eval(fn.body, scope, mod)
        try:
            self.exec_block(fn.body, scope, mod)
        except _Return as r:
            return r.value
        return UNDEF

    def call(self, fn, args: list, where: str):
        if isinstance(fn, Closure):
            self.steps += 1
            return fn(*args)
        if isinstance(fn, Builtin):
            self.steps += 1
            sites = taint_of(*args)
            r = fn(*args)
            op = getattr(fn, "math_op", None)
            if op is not None and TRACE is not None:
                approximated = op in APPROXIMATED_MATH
                if op == "pow" and len(args) >= 2:
                    x, y = to_num(args[0]), to_num(args[1])
                    approximated = not (x.is_integer() and y.is_integer() and y >= 0 and isinstance(r, float)
                                        and math.isfinite(r) and r.is_integer() and abs(r) < 2**53)
                TRACE.call(f"Math.{op}", where, approximated)
                if approximated:
                    site = f"{where} Math.{op}"
                    sites = sites | {site}
                    if TRACE.perturb:
                        r = TRACE.perturb(site, r)
            if sites:
                if isinstance(r, bool):
                    note_decision(f"built-in {fn.name}", sites, where)
                else:
                    r = tainted(r, sites)
            return r
        if isinstance(fn, Unknown):
            raise Unsupported(f"call of an unknown value ({fn.reason})", where)
        raise Unsupported(f"call of a non-function ({type(fn).__name__})", where)

    def iterate(self, v, where: str) -> list:
        if isinstance(v, list):
            return v
        if isinstance(v, str):
            return list(v)
        if isinstance(v, JSSet):
            return list(v.items)
        if isinstance(v, JSMap):
            return [[k, x] for k, x in v.pairs]
        if isinstance(v, Unknown):
            raise Unsupported(f"iteration of an unknown value ({v.reason})", where)
        raise Unsupported(f"iteration of {type(v).__name__}", where)

    # -- expressions
    def eval(self, node, scope: Scope, mod: Module):
        k = node[0]
        if k == "num":
            return node[2]
        if k == "str":
            return node[2]
        if k == "bool":
            return node[2]
        if k == "null":
            return None
        if k == "undef":
            return UNDEF
        if k == "paren":
            return self.eval(node[2], scope, mod)
        if k == "id":
            name = node[2]
            s, v = scope.lookup(name)
            if s is None:
                raise Unsupported(f"unknown identifier '{name}'", mod.where(node[1]))
            if isinstance(v, _Lazy):
                return v.get()
            return v
        if k == "tmpl":
            out = []
            for p in node[2]:
                out.append(p if isinstance(p, str) else to_str(self.eval(p, scope, mod)))
            return tainted("".join(out), taint_of(*out))
        if k == "array":
            return self.eval_array(node, scope, mod)
        if k == "object":
            return self.eval_object(node, scope, mod)
        if k == "chain":
            try:
                return self.eval(node[2], scope, mod)
            except _ShortCircuit:
                return UNDEF
        if k == "member":
            obj = self.eval(node[2], scope, mod)
            if node[4] and (obj is None or obj is UNDEF):
                raise _ShortCircuit()
            key = self.eval(node[3], scope, mod)
            return self.get(obj, key, mod.where(node[1]))
        if k == "call":
            return self.eval_call(node, scope, mod)
        if k == "new":
            return self.eval_new(node, scope, mod)
        if k == "arrow":
            return Closure(None, node[2], node[3], scope, node[4], self, mod, is_arrow=True)
        if k == "this":
            s_, v = scope.lookup("%this")
            if s_ is None or v is UNDEF:
                raise Unsupported("'this' outside a method", mod.where(node[1]))
            return v
        if k == "fnexpr":
            if node[4] is None:
                raise Unsupported("function expression without a body", mod.where(node[1]))
            return Closure(node[2], node[3], node[4], scope, False, self, mod)
        if k == "unary":
            return self.eval_unary(node, scope, mod)
        if k == "bin":
            return self.eval_binary(node, scope, mod)
        if k == "cond":
            return self.eval(node[3] if truthy(self.eval(node[2], scope, mod)) else node[4], scope, mod)
        if k == "assign":
            return self.eval_assign(node, scope, mod)
        if k == "update":
            return self.eval_update(node, scope, mod)
        if k == "seq":
            v = UNDEF
            for e in node[2]:
                v = self.eval(e, scope, mod)
            return v
        if k == "regex":
            return JSRegExp(node[2], mod.where(node[1]))
        if k == "unsupported":
            raise Unsupported(node[2], mod.where(node[1]))
        raise Unsupported(f"expression '{k}'", mod.where(node[1]))

    def eval_array(self, node, scope, mod):
        out = []
        for item in node[2]:
            if item[0] == "hole":
                out.append(UNDEF)
            elif item[0] == "spread":
                try:
                    out.extend(self.iterate(self.eval(item[2], scope, mod), mod.where(item[1])))
                except Unsupported as e:
                    out.append(Unknown(f"spread: {e.reason}", e.where or mod.where(item[1])))
            else:
                try:
                    out.append(self.eval(item, scope, mod))
                except Unsupported as e:
                    out.append(Unknown(e.reason, e.where or mod.where(item[1])))
        return out

    def eval_object(self, node, scope, mod):
        out: dict = {}
        unknown_spreads = 0
        for prop in node[2]:
            if prop[0] == "spread":
                try:
                    v = self.eval(prop[2], scope, mod)
                except Unsupported as e:
                    unknown_spreads += 1
                    out[f"$unknown_spread_{unknown_spreads}"] = Unknown(f"spread: {e.reason}", e.where or mod.where(prop[1]))
                    continue
                if isinstance(v, dict):
                    out.update(v)
                elif isinstance(v, list):
                    out.update({str(i): x for i, x in enumerate(v)})
                elif v is None or v is UNDEF:
                    pass
                elif isinstance(v, Unknown):
                    unknown_spreads += 1
                    out[f"$unknown_spread_{unknown_spreads}"] = v
                else:
                    raise Unsupported(f"spread of {type(v).__name__} into an object", mod.where(prop[1]))
                continue
            _, ppos, keynode, valnode = prop
            key = prop_key(self.eval(keynode, scope, mod))
            try:
                out[key] = self.eval(valnode, scope, mod)
            except Unsupported as e:
                out[key] = Unknown(e.reason, e.where or mod.where(ppos))
        return out

    def eval_call(self, node, scope, mod):
        _, pos, callee, argn, optional = node
        where = mod.where(pos)
        if callee[0] == "member":
            obj = self.eval(callee[2], scope, mod)
            if callee[4] and (obj is None or obj is UNDEF):
                raise _ShortCircuit()
            key = prop_key(self.eval(callee[3], scope, mod))
            if optional and isinstance(obj, dict) and obj.get(key, UNDEF) in (None, UNDEF):
                raise _ShortCircuit()  # `obj.fn?.()` with no fn
            args = self.eval_args(argn, scope, mod)
            return self.method(obj, key, args, where)
        fn = self.eval(callee, scope, mod)
        if optional and (fn is None or fn is UNDEF):
            raise _ShortCircuit()
        return self.call(fn, self.eval_args(argn, scope, mod), where)

    def eval_args(self, argn, scope, mod) -> list:
        out = []
        for a in argn:
            if a[0] == "spread":
                out.extend(self.iterate(self.eval(a[2], scope, mod), mod.where(a[1])))
            else:
                out.append(self.eval(a, scope, mod))
        return out

    def eval_new(self, node, scope, mod):
        _, pos, callee, argn = node
        name = callee[2] if callee[0] == "id" else None
        args = self.eval_args(argn, scope, mod)
        if name == "Set":
            return JSSet(self.iterate(args[0], mod.where(pos)) if args and args[0] is not UNDEF else ())
        if name == "Map":
            return JSMap(self.iterate(args[0], mod.where(pos)) if args and args[0] is not UNDEF else ())
        if name == "Error" or (name or "").endswith("Error"):
            return {"$error": to_str(args[0]) if args else ""}
        cls = self.eval(callee, scope, mod) if name not in ("Set", "Map") else None
        if isinstance(cls, JSClass):
            return self.construct(cls, args, mod.where(pos))
        raise Unsupported(f"'new {name or '...'}'", mod.where(pos))

    def construct(self, cls: JSClass, args: list, where: str) -> JSObject:
        if cls.extends:
            raise Unsupported(f"class '{cls.name}' extends '{cls.extends}'", where)
        obj = JSObject(cls)
        field_scope = Scope(cls.scope)
        field_scope.vars["%this"] = obj
        for fname, init in cls.fields:
            obj[fname] = UNDEF if init is None else self.eval(init, field_scope, cls.module)
        if cls.ctor is not None:
            self.call(cls.ctor.bound(obj), args, where)
        return obj

    def eval_unary(self, node, scope, mod):
        op = node[2]
        if op == "typeof":
            try:
                v = self.eval(node[3], scope, mod)
            except Unsupported:
                raise
            return js_typeof(v)
        v = self.eval(node[3], scope, mod)
        if isinstance(v, Unknown):
            raise Unsupported(f"operator '{op}' on an unknown value ({v.reason})", mod.where(node[1]))
        if op == "!":
            return not truthy(v)
        if op == "-":
            return tainted(-to_num(v), taint_of(v))
        if op == "+":
            return tainted(to_num(v), taint_of(v))
        if op == "~":
            return tainted(float(~to_int32(v)), taint_of(v))
        if op == "void":
            return UNDEF
        raise Unsupported(f"unary '{op}'", mod.where(node[1]))

    def eval_binary(self, node, scope, mod):
        _, pos, op, ln, rn = node
        if op == "&&":
            a = self.eval(ln, scope, mod)
            return self.eval(rn, scope, mod) if truthy(a) else a
        if op == "||":
            a = self.eval(ln, scope, mod)
            return a if truthy(a) else self.eval(rn, scope, mod)
        if op == "??":
            a = self.eval(ln, scope, mod)
            return self.eval(rn, scope, mod) if a is None or a is UNDEF else a
        a = self.eval(ln, scope, mod)
        b = self.eval(rn, scope, mod)
        return binop(op, a, b, mod.where(pos))

    def eval_assign(self, node, scope, mod):
        _, pos, op, target, valnode = node
        where = mod.where(pos)
        if op in ("&&=", "||=", "??="):
            cur = self.eval(target, scope, mod)
            if (op == "&&=" and not truthy(cur)) or (op == "||=" and truthy(cur)) or (
                    op == "??=" and not (cur is None or cur is UNDEF)):
                return cur
            value = self.eval(valnode, scope, mod)
        elif op == "=":
            value = self.eval(valnode, scope, mod)
        else:
            cur = self.eval(target, scope, mod)
            value = binop(op[:-1], cur, self.eval(valnode, scope, mod), where)
        self.store(target, value, scope, mod, where)
        return value

    def store(self, target, value, scope, mod, where):
        k = target[0]
        if k == "id":
            s, cur = scope.lookup(target[2])
            if s is None:
                raise Unsupported(f"assignment to undeclared '{target[2]}'", where)
            if isinstance(cur, _Lazy):
                if target[2] not in s.mutable:
                    raise Unsupported(f"assignment to module constant or import '{target[2]}'", where)
                cur.get()
            s.vars[target[2]] = value
        elif k == "member":
            obj = self.eval(target[2], scope, mod)
            key = self.eval(target[3], scope, mod)
            if isinstance(obj, dict):
                obj[prop_key(key)] = value
            elif isinstance(obj, list) and is_num(key) and key.is_integer() and key >= 0:
                idx = int(key)
                while len(obj) <= idx:
                    obj.append(UNDEF)
                obj[idx] = value
            else:
                raise Unsupported("assignment into a non-plain object", where)
        elif k == "paren":
            self.store(target[2], value, scope, mod, where)
        else:
            raise Unsupported("destructuring assignment", where)

    def eval_update(self, node, scope, mod):
        _, pos, op, prefix, target = node
        cur = to_num(self.eval(target, scope, mod))
        new = cur + 1 if op == "++" else cur - 1
        self.store(target, new, scope, mod, mod.where(pos))
        return new if prefix else cur

    # -- property access
    def get(self, obj, key, where: str):
        if isinstance(obj, Unknown):
            raise Unsupported(f"property of an unknown value ({obj.reason})", where)
        if isinstance(obj, Namespace):
            return obj.module.export(prop_key(key))
        if isinstance(obj, JSClass):
            return obj.static(prop_key(key))
        if isinstance(obj, dict):
            k = prop_key(key)
            if k in obj:
                v = obj[k]
                if isinstance(v, Unknown):
                    raise Unsupported(f"'{k}' is unknown ({v.reason})", v.where)
                return v
            if isinstance(obj, JSObject) and k in obj.jsclass.methods:
                m = obj.jsclass.methods[k]
                if isinstance(m, Unknown):
                    raise Unsupported(m.reason, m.where)
                return m.bound(obj)
            return UNDEF
        if isinstance(obj, list):
            note_decision("array index", taint_of(key), where)
            if is_num(key):
                if key.is_integer() and 0 <= key < len(obj):
                    v = obj[int(key)]
                    if isinstance(v, Unknown):
                        raise Unsupported(f"element is unknown ({v.reason})", v.where)
                    return v
                return UNDEF
            if key == "length":
                return float(len(obj))
            raise Unsupported(f"array property '{key}' used as a value", where)
        if isinstance(obj, str):
            if is_num(key):
                return obj[int(key)] if key.is_integer() and 0 <= key < len(obj) else UNDEF
            if key == "length":
                return float(len(obj))
            raise Unsupported(f"string property '{key}' used as a value", where)
        if isinstance(obj, (JSSet, JSMap)) and key == "size":
            return float(len(obj.items if isinstance(obj, JSSet) else obj.pairs))
        if isinstance(obj, Builtin) and isinstance(obj.fn, dict):
            v = obj.fn.get(prop_key(key), UNDEF)
            return v
        if isinstance(obj, (Closure, Builtin)) and key == "name":
            return obj.name or ""
        if obj is None or obj is UNDEF:
            raise Unsupported(f"property '{to_str(key) if not isinstance(key, Unknown) else '?'}' of {to_str(obj)}", where)
        raise Unsupported(f"property '{key}' of {type(obj).__name__}", where)

    def method(self, obj, name: str, args: list, where: str):
        if isinstance(obj, Unknown):
            raise Unsupported(f"method '{name}' of an unknown value ({obj.reason})", where)
        if isinstance(obj, Namespace):
            return self.call(obj.module.export(name), args, where)
        if isinstance(obj, list):
            return array_method(self, obj, name, args, where)
        if isinstance(obj, str):
            note_decision(f"string method {name}", taint_of(obj, *args), where)
            return string_method(obj, name, args, where)
        if is_num(obj):
            return number_method(obj, name, args, where)
        if isinstance(obj, JSRegExp):
            text = to_str(args[0]) if args else "undefined"
            if name == "exec":
                return obj.exec(text)
            if name == "test":
                return obj.exec(text) is not None
            raise Unsupported(f"RegExp method '{name}'", where)
        if isinstance(obj, JSSet):
            return set_method(self, obj, name, args, where)
        if isinstance(obj, JSMap):
            return map_method(self, obj, name, args, where)
        if isinstance(obj, Builtin) and isinstance(obj.fn, dict):
            fn = obj.fn.get(name)
            if fn is None:
                raise Unsupported(f"'{obj.name}.{name}'", where)
            return self.call(fn, args, where)
        if isinstance(obj, JSClass):
            return self.call(obj.static(name), args, where)
        if isinstance(obj, dict):
            fn = obj.get(name, UNDEF)
            if fn is UNDEF and isinstance(obj, JSObject) and name in obj.jsclass.methods:
                m = obj.jsclass.methods[name]
                if isinstance(m, Unknown):
                    raise Unsupported(m.reason, m.where)
                fn = m.bound(obj)
            if isinstance(fn, (Closure, Builtin)):
                return self.call(fn, args, where)
            if name == "hasOwnProperty":
                return prop_key(args[0]) in obj
            raise Unsupported(f"object method '{name}'", where)
        if isinstance(obj, (Closure, Builtin)) and name in ("call", "apply", "bind"):
            raise Unsupported(f"function '{name}'", where)
        raise Unsupported(f"method '{name}' of {type(obj).__name__}", where)


def js_typeof(v) -> str:
    if v is UNDEF:
        return "undefined"
    if isinstance(v, bool):
        return "boolean"
    if is_num(v):
        return "number"
    if isinstance(v, str):
        return "string"
    if isinstance(v, (Closure, Builtin)):
        return "function"
    return "object"


def binop(op: str, a, b, where: str):
    sites = taint_of(a, b)
    if op == "**":
        x, y = to_num(a), to_num(b)
        r = _pow(x, y)
        # Exact when both are integers and the result is an integer below 2^53
        # (representable, so every conforming engine returns it); otherwise the
        # engine approximates.
        exact = x.is_integer() and y.is_integer() and y >= 0 and math.isfinite(r) and r.is_integer() and abs(r) < 2**53
        if TRACE is not None:
            TRACE.call("**", where, not exact)
        if not exact:
            site = f"{where} **"
            sites = sites | {site}
            if TRACE is not None and TRACE.perturb:
                r = TRACE.perturb(site, r)
        return ApproxFloat(r, sites) if sites else r
    r = _binop(op, a, b, where)
    if sites:
        if isinstance(r, bool):
            note_decision(f"operator {op}", sites, where)
            return r
        return tainted(r, sites)
    return r


def _pow(x: float, y: float) -> float:
    try:
        r = math.pow(x, y)
    except (ValueError, OverflowError):
        if math.isnan(x) or math.isnan(y) or (x < 0 and not y.is_integer()):
            return math.nan
        return math.inf if abs(x) > 1 and y > 0 or abs(x) < 1 and y < 0 else 0.0
    return float(r)


def _binop(op: str, a, b, where: str):
    if isinstance(a, Unknown) or isinstance(b, Unknown):
        u = a if isinstance(a, Unknown) else b
        raise Unsupported(f"operator '{op}' on an unknown value ({u.reason})", u.where)
    if op == "+":
        if isinstance(a, str) or isinstance(b, str) or isinstance(a, list) or isinstance(b, list):
            return to_str(a) + to_str(b)
        return to_num(a) + to_num(b)
    if op == "-":
        return to_num(a) - to_num(b)
    if op == "*":
        return to_num(a) * to_num(b)
    if op == "/":
        x, y = to_num(a), to_num(b)
        if y == 0:
            if x == 0 or math.isnan(x):
                return math.nan
            return math.copysign(math.inf, x) * math.copysign(1, y)
        return x / y
    if op == "%":
        x, y = to_num(a), to_num(b)
        if y == 0 or math.isinf(x) or math.isnan(x) or math.isnan(y):
            return math.nan
        if math.isinf(y):
            return x
        return math.fmod(x, y)
    if op == "===":
        return strict_eq(a, b)
    if op == "!==":
        return not strict_eq(a, b)
    if op in ("==", "!="):
        if (a is None or a is UNDEF) and (b is None or b is UNDEF):
            eq = True
        elif type(a) is not type(b) and not (is_num(a) and is_num(b)):
            if (a is None or a is UNDEF) or (b is None or b is UNDEF):
                eq = False
            else:
                raise Unsupported("loose equality across types", where)
        else:
            eq = strict_eq(a, b)
        return eq if op == "==" else not eq
    if op in ("<", ">", "<=", ">="):
        if isinstance(a, str) and isinstance(b, str):
            x, y = a, b
        else:
            x, y = to_num(a), to_num(b)
            if math.isnan(x) or math.isnan(y):
                return False
        return {"<": x < y, ">": x > y, "<=": x <= y, ">=": x >= y}[op]
    if op == "in":
        if isinstance(b, dict):
            return prop_key(a) in b
        if isinstance(b, list):
            return is_num(a) and a.is_integer() and 0 <= a < len(b)
        raise Unsupported("'in' on a non-object", where)
    if op in ("&", "|", "^", "<<", ">>"):
        x, y = to_int32(a), to_int32(b)
        r = {"&": x & y, "|": x | y, "^": x ^ y, "<<": x << (y & 31), ">>": x >> (y & 31)}[op]
        return float(to_int32(float(r)))
    if op == ">>>":
        return float((to_int32(a) & 0xFFFFFFFF) >> (to_int32(b) & 31))
    raise Unsupported(f"operator '{op}'", where)


class _ShortCircuit(Exception):
    """An optional link met null or undefined: its chain evaluates to undefined."""


class _ObjectPrototype:
    """Object.prototype, as an identity only (compared with ===, never read)."""

    def __repr__(self) -> str:
        return "Object.prototype"


OBJECT_PROTOTYPE = _ObjectPrototype()


def get_prototype_of(v=UNDEF, *_):
    if type(v) is dict:
        return OBJECT_PROTOTYPE
    raise Unsupported(f"Object.getPrototypeOf of {type(v).__name__}")


def from_json(v):
    if isinstance(v, bool) or v is None or isinstance(v, str):
        return v
    if isinstance(v, (int, float)):
        return float(v)
    if isinstance(v, list):
        return [from_json(x) for x in v]
    return {k: from_json(x) for k, x in v.items()}


# ---------------------------------------------------------------------------
# Built-ins (standard library behaviour only)


def _cb(interp, fn, where):
    def call(*a):
        return interp.call(fn, list(a), where)
    return call


def _idx(x) -> int:
    return int(to_num(x))


def _slice_bounds(n: int, args) -> tuple[int, int]:
    def norm(v, default):
        if v is UNDEF:
            return default
        x = to_num(v)
        if math.isnan(x):
            return 0
        if math.isinf(x):
            return n if x > 0 else 0
        i = int(x)
        return max(0, n + i) if i < 0 else min(i, n)
    start = norm(args[0], 0) if len(args) > 0 and args[0] is not UNDEF else 0
    end = norm(args[1], n) if len(args) > 1 and args[1] is not UNDEF else n
    return start, end


def _cmp_default(a, b) -> int:
    if a is UNDEF:
        return 0 if b is UNDEF else 1
    if b is UNDEF:
        return -1
    sa, sb = to_str(a), to_str(b)
    # JavaScript compares UTF-16 code units.
    ka, kb = sa.encode("utf-16-be"), sb.encode("utf-16-be")
    return (ka > kb) - (ka < kb)


def array_method(interp: Interpreter, arr: list, name: str, args: list, where: str):
    a0 = args[0] if args else UNDEF
    if name == "map":
        f = _cb(interp, a0, where)
        return [f(v, float(i), arr) for i, v in enumerate(arr)]
    if name == "filter":
        f = _cb(interp, a0, where)
        return [v for i, v in enumerate(arr) if truthy(f(v, float(i), arr))]
    if name == "flatMap":
        f = _cb(interp, a0, where)
        out = []
        for i, v in enumerate(arr):
            r = f(v, float(i), arr)
            out.extend(r if isinstance(r, list) else [r])
        return out
    if name == "forEach":
        f = _cb(interp, a0, where)
        for i, v in enumerate(list(arr)):
            f(v, float(i), arr)
        return UNDEF
    if name == "reduce":
        f = _cb(interp, a0, where)
        items = list(enumerate(arr))
        if len(args) > 1:
            acc = args[1]
        else:
            if not items:
                raise Unsupported("reduce of an empty array with no initial value", where)
            acc = items[0][1]
            items = items[1:]
        for i, v in items:
            acc = f(acc, v, float(i), arr)
        return acc
    if name in ("some", "every", "find", "findIndex", "findLast"):
        f = _cb(interp, a0, where)
        seq = list(enumerate(arr))
        if name == "findLast":
            seq = seq[::-1]
        for i, v in seq:
            r = truthy(f(v, float(i), arr))
            if name == "some" and r:
                return True
            if name == "every" and not r:
                return False
            if name in ("find", "findLast") and r:
                return v
            if name == "findIndex" and r:
                return float(i)
        return {"some": False, "every": True, "find": UNDEF, "findLast": UNDEF, "findIndex": -1.0}[name]
    if name == "includes":
        return any(strict_eq(v, a0) or (is_num(v) and is_num(a0) and math.isnan(v) and math.isnan(a0)) for v in arr)
    if name == "indexOf":
        for i, v in enumerate(arr):
            if strict_eq(v, a0):
                return float(i)
        return -1.0
    if name == "concat":
        out = list(arr)
        for x in args:
            out.extend(x if isinstance(x, list) else [x])
        return out
    if name == "slice":
        s, e = _slice_bounds(len(arr), args)
        return arr[s:e]
    if name == "join":
        sep = "," if a0 is UNDEF else to_str(a0)
        return sep.join("" if v is None or v is UNDEF else to_str(v) for v in arr)
    if name == "flat":
        depth = 1 if a0 is UNDEF else _idx(a0)

        def flat(xs, d):
            out = []
            for x in xs:
                if isinstance(x, list) and d > 0:
                    out.extend(flat(x, d - 1))
                else:
                    out.append(x)
            return out
        return flat(arr, depth)
    if name == "push":
        arr.extend(args)
        return float(len(arr))
    if name == "unshift":
        arr[0:0] = args
        return float(len(arr))
    if name == "pop":
        return arr.pop() if arr else UNDEF
    if name == "shift":
        return arr.pop(0) if arr else UNDEF
    if name == "reverse":
        arr.reverse()
        return arr
    if name in ("sort", "toSorted"):
        target = arr if name == "sort" else list(arr)
        if a0 is UNDEF:
            key = functools.cmp_to_key(_cmp_default)
        else:
            f = _cb(interp, a0, where)

            def cmp(x, y):
                r = to_num(f(x, y))
                note_decision("sort comparator", taint_of(r), where)
                return -1 if r < 0 else 1 if r > 0 else 0
            key = functools.cmp_to_key(cmp)
        target.sort(key=key)  # Python's sort is stable, as ES2019 requires
        return target
    if name == "fill":
        v = a0
        s, e = _slice_bounds(len(arr), args[1:])
        for i in range(s, e):
            arr[i] = v
        return arr
    if name == "keys":
        return [float(i) for i in range(len(arr))]
    if name == "entries":
        return [[float(i), v] for i, v in enumerate(arr)]
    if name == "values":
        return list(arr)
    if name == "splice":
        n = len(arr)
        start = _idx(a0) if a0 is not UNDEF else 0
        start = max(0, n + start) if start < 0 else min(start, n)
        count = n - start if len(args) < 2 or args[1] is UNDEF else max(0, min(_idx(args[1]), n - start))
        removed = arr[start:start + count]
        arr[start:start + count] = list(args[2:])
        return removed
    if name == "at":
        i = _idx(a0)
        i = len(arr) + i if i < 0 else i
        return arr[i] if 0 <= i < len(arr) else UNDEF
    raise Unsupported(f"array method '{name}'", where)


def string_method(s: str, name: str, args: list, where: str):
    a0 = args[0] if args else UNDEF
    if name == "toUpperCase":
        return s.upper()
    if name == "toLowerCase":
        return s.lower()
    if name == "trim":
        return s.strip()
    if name in ("startsWith", "endsWith", "includes"):
        sub = to_str(a0)
        return {"startsWith": s.startswith(sub), "endsWith": s.endswith(sub), "includes": sub in s}[name]
    if name == "indexOf":
        return float(s.find(to_str(a0)))
    if name in ("slice", "substring"):
        if name == "substring":
            n = len(s)
            st = min(max(_idx(a0), 0), n) if a0 is not UNDEF else 0
            en = min(max(_idx(args[1]), 0), n) if len(args) > 1 and args[1] is not UNDEF else n
            st, en = min(st, en), max(st, en)
            return s[st:en]
        st, en = _slice_bounds(len(s), args)
        return s[st:en]
    if name == "split":
        if isinstance(a0, str):
            return s.split(a0) if a0 else list(s)
        raise Unsupported("split by a non-string", where)
    if name == "replace" or name == "replaceAll":
        if isinstance(a0, str) and len(args) > 1 and isinstance(args[1], str) and "$" not in args[1]:
            return s.replace(a0, args[1], 1 if name == "replace" else -1)
        if isinstance(a0, JSRegExp) and len(args) > 1 and isinstance(args[1], str):
            repl = args[1]

            def sub(m):
                out, i = [], 0
                while i < len(repl):
                    if repl[i] == "$" and i + 1 < len(repl):
                        n = repl[i + 1]
                        if n == "$":
                            out.append("$"); i += 2; continue
                        if n == "&":
                            out.append(m.group(0)); i += 2; continue
                        if n.isdigit():
                            g = int(n)
                            if g <= (m.re.groups or 0):
                                out.append(m.group(g) or ""); i += 2; continue
                    out.append(repl[i]); i += 1
                return "".join(out)
            count = 0 if "g" in a0.flags else 1
            return a0.pattern.sub(sub, s, count=count)
        raise Unsupported(f"string '{name}' with a callback or unsupported pattern", where)
    if name == "match" and isinstance(a0, JSRegExp) and "g" not in a0.flags:
        return a0.exec(s)
    if name == "search" and isinstance(a0, JSRegExp):
        m = a0.pattern.search(s)
        return float(m.start()) if m else -1.0
    if name == "charAt":
        i = _idx(a0) if a0 is not UNDEF else 0
        return s[i] if 0 <= i < len(s) else ""
    if name == "padStart" or name == "padEnd":
        width = _idx(a0)
        fill = " " if len(args) < 2 or args[1] is UNDEF else to_str(args[1])
        need = width - len(s)
        if need <= 0 or not fill:
            return s
        pad = (fill * (need // len(fill) + 1))[:need]
        return pad + s if name == "padStart" else s + pad
    if name == "repeat":
        return s * _idx(a0)
    if name == "concat":
        return s + "".join(to_str(x) for x in args)
    if name == "toString":
        return s
    raise Unsupported(f"string method '{name}'", where)


def number_method(x: float, name: str, args: list, where: str):
    if name == "toString" and (not args or args[0] is UNDEF):
        return num_to_str(x)
    raise Unsupported(f"number method '{name}'", where)


def set_method(interp, s: JSSet, name, args, where):
    a0 = args[0] if args else UNDEF
    if name == "has":
        return s.has(a0)
    if name == "add":
        return s.add(a0)
    if name == "delete":
        for i, x in enumerate(s.items):
            if strict_eq(x, a0):
                del s.items[i]
                return True
        return False
    if name == "clear":
        s.items.clear()
        return UNDEF
    if name in ("values", "keys"):
        return list(s.items)
    if name == "forEach":
        f = _cb(interp, a0, where)
        for v in list(s.items):
            f(v, v, s)
        return UNDEF
    raise Unsupported(f"Set method '{name}'", where)


def map_method(interp, m: JSMap, name, args, where):
    a0 = args[0] if args else UNDEF
    if name == "get":
        return m.get(a0)
    if name == "has":
        return m._find(a0) is not None
    if name == "set":
        return m.set(a0, args[1] if len(args) > 1 else UNDEF)
    if name == "delete":
        p = m._find(a0)
        if p is None:
            return False
        m.pairs.remove(p)
        return True
    if name == "keys":
        return [k for k, _ in m.pairs]
    if name == "values":
        return [v for _, v in m.pairs]
    if name == "entries":
        return [[k, v] for k, v in m.pairs]
    if name == "forEach":
        f = _cb(interp, a0, where)
        for k, v in list(m.pairs):
            f(v, k, m)
        return UNDEF
    raise Unsupported(f"Map method '{name}'", where)


def make_globals(interp: Interpreter) -> dict:
    def obj_keys(o):
        if isinstance(o, dict):
            return list(o.keys())
        if isinstance(o, list):
            return [str(i) for i in range(len(o))]
        raise Unsupported("Object.keys of a non-object")

    def obj_values(o):
        if isinstance(o, dict):
            return list(o.values())
        if isinstance(o, list):
            return list(o)
        raise Unsupported("Object.values of a non-object")

    def obj_entries(o):
        if isinstance(o, dict):
            return [[k, v] for k, v in o.items()]
        if isinstance(o, list):
            return [[str(i), v] for i, v in enumerate(o)]
        raise Unsupported("Object.entries of a non-object")

    def from_entries(it):
        out = {}
        for pair in interp.iterate(it, "Object.fromEntries"):
            out[prop_key(pair[0])] = pair[1] if len(pair) > 1 else UNDEF
        return out

    def assign(target, *sources):
        if not isinstance(target, dict):
            raise Unsupported("Object.assign onto a non-object")
        for s in sources:
            if isinstance(s, dict):
                target.update(s)
        return target

    def array_from(it, fn=UNDEF):
        if isinstance(it, dict) and "length" in it and len(it) == 1:
            items = [UNDEF] * int(to_num(it["length"]))
        else:
            items = interp.iterate(it, "Array.from")
        if fn is UNDEF:
            return list(items)
        return [interp.call(fn, [v, float(i)], "Array.from") for i, v in enumerate(items)]

    def num_fn(f):
        return lambda *a: float(f(*[to_num(x) for x in a]))

    def js_round(x):
        x = to_num(x)
        if math.isnan(x) or math.isinf(x):
            return x
        return float(math.floor(x + 0.5))

    def js_max(*a):
        if not a:
            return -math.inf
        vals = [to_num(x) for x in a]
        return math.nan if any(math.isnan(v) for v in vals) else max(vals)

    def js_min(*a):
        if not a:
            return math.inf
        vals = [to_num(x) for x in a]
        return math.nan if any(math.isnan(v) for v in vals) else min(vals)

    def trunc(x):
        x = to_num(x)
        return x if math.isnan(x) or math.isinf(x) else float(math.trunc(x))

    def floor(x):
        x = to_num(x)
        return x if math.isnan(x) or math.isinf(x) else float(math.floor(x))

    def ceil(x):
        x = to_num(x)
        return x if math.isnan(x) or math.isinf(x) else float(math.ceil(x))

    obj = Builtin("Object", {
        "freeze": Builtin("Object.freeze", lambda o=UNDEF, *_: o),
        "keys": Builtin("Object.keys", obj_keys),
        "values": Builtin("Object.values", obj_values),
        "entries": Builtin("Object.entries", obj_entries),
        "fromEntries": Builtin("Object.fromEntries", from_entries),
        "assign": Builtin("Object.assign", assign),
        "hasOwn": Builtin("Object.hasOwn", lambda o=UNDEF, k=UNDEF, *_: isinstance(o, dict) and prop_key(k) in o),
        # Only the plain-record test (`getPrototypeOf(v) === Object.prototype`) is
        # supported: a plain object literal answers OBJECT_PROTOTYPE; anything else
        # is not decided here.
        "prototype": OBJECT_PROTOTYPE,
        "getPrototypeOf": Builtin("Object.getPrototypeOf", get_prototype_of),
    })
    arr = Builtin("Array", {
        "isArray": Builtin("Array.isArray", lambda v=UNDEF, *_: isinstance(v, list)),
        "from": Builtin("Array.from", array_from),
    })
    mth = Builtin("Math", {
        "max": Builtin("Math.max", js_max),
        "min": Builtin("Math.min", js_min),
        "floor": Builtin("Math.floor", floor),
        "ceil": Builtin("Math.ceil", ceil),
        "round": Builtin("Math.round", js_round),
        "trunc": Builtin("Math.trunc", trunc),
        "abs": Builtin("Math.abs", num_fn(abs)),
        "sqrt": Builtin("Math.sqrt", num_fn(math.sqrt)),
        "hypot": Builtin("Math.hypot", num_fn(lambda *a: math.hypot(*a))),
        "imul": Builtin("Math.imul", lambda a=UNDEF, b=UNDEF, *_: float(to_int32(float((to_int32(a) * to_int32(b)) & 0xFFFFFFFF)))),
        "sin": Builtin("Math.sin", num_fn(math.sin)),
        "cos": Builtin("Math.cos", num_fn(math.cos)),
        "atan2": Builtin("Math.atan2", num_fn(math.atan2)),
        "tan": Builtin("Math.tan", num_fn(math.tan)),
        "asin": Builtin("Math.asin", num_fn(lambda x: math.asin(x) if -1 <= x <= 1 else math.nan)),
        "acos": Builtin("Math.acos", num_fn(lambda x: math.acos(x) if -1 <= x <= 1 else math.nan)),
        "atan": Builtin("Math.atan", num_fn(math.atan)),
        "exp": Builtin("Math.exp", num_fn(math.exp)),
        "log": Builtin("Math.log", num_fn(lambda x: math.log(x) if x > 0 else (-math.inf if x == 0 else math.nan))),
        "log2": Builtin("Math.log2", num_fn(lambda x: math.log2(x) if x > 0 else (-math.inf if x == 0 else math.nan))),
        "log10": Builtin("Math.log10", num_fn(lambda x: math.log10(x) if x > 0 else (-math.inf if x == 0 else math.nan))),
        "cbrt": Builtin("Math.cbrt", num_fn(lambda x: math.copysign(abs(x) ** (1 / 3), x))),
        "E": math.e,
        "SQRT2": math.sqrt(2),
        "sign": Builtin("Math.sign", num_fn(lambda x: x if x == 0 or math.isnan(x) else math.copysign(1.0, x))),
        "pow": Builtin("Math.pow", num_fn(_pow)),
        "PI": math.pi,
    })
    for op, b in mth.fn.items():
        if isinstance(b, Builtin):
            b.math_op = op
    number = Builtin("Number", {
        "isFinite": Builtin("Number.isFinite", lambda v=UNDEF, *_: is_num(v) and math.isfinite(v)),
        "isInteger": Builtin("Number.isInteger", lambda v=UNDEF, *_: is_num(v) and math.isfinite(v) and v.is_integer()),
        "POSITIVE_INFINITY": math.inf,
        "NEGATIVE_INFINITY": -math.inf,
        "MAX_SAFE_INTEGER": float(2**53 - 1),
        "EPSILON": 2.0 ** -52,
        "isSafeInteger": Builtin("Number.isSafeInteger", lambda v=UNDEF, *_: is_num(v) and math.isfinite(v)
                                 and v.is_integer() and abs(v) <= 2**53 - 1),
        "__call__": lambda v=0.0, *_: to_num(v),
    })
    return {
        "Object": obj,
        "Array": arr,
        "Math": mth,
        "Number": number,
        "String": Builtin("String", lambda v=UNDEF, *_: to_str(v)),
        "Boolean": Builtin("Boolean", lambda v=UNDEF, *_: truthy(v)),
        "Infinity": math.inf,
        "NaN": math.nan,
    }
