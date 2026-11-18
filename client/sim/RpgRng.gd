class_name RpgRng
extends RefCounted
## World of ClaudeCraft's random number generator (src/sim/rng.ts `Rng`, mulberry32)
## with its draw semantics, so a reward or combat roll here consumes the same draws
## in the same order as the reference:
## * next() in [0, 1);
## * int(min, max) = floor(min + next() * (max + 1 - min)), both bounds inclusive;
## * chance(p) = next() < p;
## * range(min, max) = min + next() * (max - min);
## * pick(a) = a[floor(next() * a.size())].
## Seeded and serialisable (state()), never the global generator (client/sim rules).

const ZERO_SEED := 0x9E3779B9
const MASK := 0xFFFFFFFF

var s: int = ZERO_SEED
## Every draw in order, when tracing is on (tests compare draw logs).
var trace: Array = []
var tracing := false
## Scripted next() values (tests and parity fixtures); empty means the generator.
var scripted_values: Array = []


static func seeded(seed: int) -> RpgRng:
	var r := RpgRng.new()
	r.s = seed & MASK
	if r.s == 0:
		r.s = ZERO_SEED
	return r


## A generator that returns `values` from next(), in order (parity fixtures).
static func scripted(values: Array) -> RpgRng:
	var r := RpgRng.new()
	r.scripted_values = values.duplicate()
	return r


static func _imul(a: int, b: int) -> int:
	return ((a & MASK) * (b & MASK)) & MASK


func next() -> float:
	var value: float
	if not scripted_values.is_empty():
		value = float(scripted_values.pop_front())
	else:
		s = (s + 0x6D2B79F5) & MASK
		var t := s
		t = _imul(t ^ (t >> 15), t | 1)
		t ^= (t + _imul(t ^ (t >> 7), t | 61)) & MASK
		value = float((t ^ (t >> 14)) & MASK) / 4294967296.0
	if tracing:
		trace.append(["next", value])
	return value


func range_f(lo: float, hi: float) -> float:
	return lo + next() * (hi - lo)


func int_range(lo: int, hi: int) -> int:
	return floori(range_f(lo, hi + 1))


func chance(p: float) -> bool:
	return next() < p


func pick(arr: Array) -> Variant:
	return arr[floori(next() * arr.size())]


func state() -> int:
	return s
