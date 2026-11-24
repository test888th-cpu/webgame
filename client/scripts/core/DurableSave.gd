class_name DurableSave
extends RefCounted
## Saves that report completion. SaveStore.save_player and GameSession.set_setting
## write user:// at once. On the web user:// lives in memory and Godot copies it to
## IndexedDB (IDBFS: database "/userfs", store FILE_DATA, keyed by absolute path)
## in the background, seconds behind and far more under load, so a reload before
## that copy would lose the write.
##
## So every write is also committed here, with these guarantees:
## * Each request() gets a sequence number. Commits for one file run one at a time,
##   and each writes the newest text requested so far, so the browser store never
##   goes back to an older state (Godot's own later copy writes the same or newer).
## * A request is durable only when a commit of that text, or of a newer one, has
##   completed: the IndexedDB transaction's oncomplete. Nothing else counts.
## * A commit is never abandoned: an error or abort retries it, and a slow store is
##   waited for. Callers wait on their own number (wait_durable), with their own
##   time limit, and a time-out reports "not yet", never success.
## Off the web a closed file is already on disk: a request is durable at once.

## The page side, installed once: one IndexedDB connection reused for every commit
## (reopened if the browser closes it), each commit one readwrite transaction that
## writes the file's record, and its parent folders' records if missing, in the
## format Godot restores from at start.
const JS := """
window.ironLegacyIdb = window.ironLegacyIdb || {db: null, waiting: [], results: {}};
window.ironLegacyIdbTake = function (t) {
	var s = window.ironLegacyIdb, r = s.results[t] || '';
	if (r) { delete s.results[t]; }
	return r;
};
window.ironLegacyIdbWith = function (use) {
	var s = window.ironLegacyIdb;
	if (s.db) { use(s.db); return; }
	s.waiting.push(use);
	if (s.waiting.length > 1) { return; }
	var open = indexedDB.open('/userfs');
	var flush = function (db) {
		var w = s.waiting; s.waiting = [];
		w.forEach(function (f) { f(db); });
	};
	open.onerror = function () { flush(null); };
	open.onsuccess = function () {
		var db = open.result;
		db.onversionchange = function () { db.close(); s.db = null; };
		db.onclose = function () { s.db = null; };
		s.db = db;
		flush(db);
	};
};
window.ironLegacyIdbCommit = function (key, text, t) {
	var s = window.ironLegacyIdb;
	var done = function (r) { s.results[t] = r; };
	window.ironLegacyIdbWith(function (db) {
		if (!db) { done('error'); return; }
		try {
			var tx = db.transaction(['FILE_DATA'], 'readwrite');
			var store = tx.objectStore('FILE_DATA');
			var now = new Date();
			var parts = key.split('/');
			for (var i = 3; i < parts.length; i++) {
				(function (dir) {
					var get = store.get(dir);
					get.onsuccess = function () {
						if (!get.result) { store.put({timestamp: now, mode: 16895}, dir); }
					};
				})(parts.slice(0, i).join('/'));
			}
			var old = store.get(key);
			old.onsuccess = function () {
				var mode = old.result && old.result.mode ? old.result.mode : 33206;
				var bytes = new TextEncoder().encode(text);
				store.put({timestamp: new Date(), mode: mode, contents: bytes}, key);
			};
			tx.oncomplete = function () { done('ok'); };
			tx.onerror = function () { done('error'); };
			tx.onabort = function () { done('error'); };
		} catch (err) { s.db = null; done('error'); }
	});
};
"""
## Frames between a failed commit and its retry.
const RETRY_FRAMES := 30

## Tests replace the commit step: Callable(key: String, text: String) -> String
## ("ok" or an error), awaited. Set, it also turns the web path on off the web.
static var committer := Callable()
static var _installed := false
static var _token := 0
static var _seq := 0
## By globalized path: the newest text requested, its number, the number of the
## newest durable text, whether a commit is running, the last commit error, and
## (with a test committer only) every text committed, in order.
static var _text := {}
static var _requested := {}
static var _durable := {}
static var _running := {}
static var _error := {}
static var history := {}


## Save `state` (SaveStore.save_player) and wait until it, or a newer save, is durable.
static func save_player(state: Dictionary, seconds := 60.0) -> bool:
	if not SaveStore.save_player(state):
		return false
	var path := SaveStore.player_folder().path_join(str(state["id"]) + ".json")
	return await wait_durable(path, request(path), seconds)


## Request and wait (the settings file and other single files).
static func persisted(path: String, seconds := 60.0) -> bool:
	return await wait_durable(path, request(path), seconds)


## `path` was just written: commit its current text. Returns the request's number.
static func request(path: String) -> int:
	var key := ProjectSettings.globalize_path(path)
	_seq += 1
	_text[key] = FileAccess.get_file_as_string(path)
	_requested[key] = _seq
	if not _web():
		_durable[key] = _seq
		return _seq
	if not _running.get(key, false):
		_pump(key)
	return _seq


## True once request `seq` on `path`, or a newer one, is durable; false if that has
## not happened within `seconds` (the commit goes on regardless).
static func wait_durable(path: String, seq: int, seconds := 60.0) -> bool:
	var key := ProjectSettings.globalize_path(path)
	var tree := Engine.get_main_loop() as SceneTree
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while int(_durable.get(key, 0)) < seq:
		if Time.get_ticks_msec() >= deadline:
			return false
		await tree.process_frame
	return true


## The newest request's number on `path`, and the newest durable one.
static func requested_seq(path: String) -> int:
	return int(_requested.get(ProjectSettings.globalize_path(path), 0))


static func durable_seq(path: String) -> int:
	return int(_durable.get(ProjectSettings.globalize_path(path), 0))


static func last_error(path: String) -> String:
	return str(_error.get(ProjectSettings.globalize_path(path), ""))


## Tests: forget every request.
static func reset() -> void:
	_seq = 0
	for d: Dictionary in [_text, _requested, _durable, _running, _error, history]:
		d.clear()


static func _web() -> bool:
	return committer.is_valid() or OS.has_feature("web")


## Commit the newest text for `key` until the newest request is durable; one at a
## time, so commits land in request order and the last one is the newest.
static func _pump(key: String) -> void:
	_running[key] = true
	var tree := Engine.get_main_loop() as SceneTree
	while int(_durable.get(key, 0)) < int(_requested[key]):
		var seq: int = _requested[key]
		var text: String = _text[key]
		var result: String = await _commit(key, text)
		if result == "ok":
			_durable[key] = maxi(int(_durable.get(key, 0)), seq)
			_error.erase(key)
			if committer.is_valid():
				# Tests only: the texts committed, in order (unbounded otherwise).
				if not history.has(key):
					history[key] = []
				history[key].append(text)
		else:
			_error[key] = result
			push_warning("save commit failed (%s), retrying: %s" % [result, key])
			for _i in RETRY_FRAMES:
				await tree.process_frame
	_running[key] = false


static func _commit(key: String, text: String) -> String:
	if committer.is_valid():
		return await committer.call(key, text)
	if not _installed:
		_installed = true
		JavaScriptBridge.eval(JS, true)
	_token += 1
	var token := str(_token)
	JavaScriptBridge.get_interface("window").ironLegacyIdbCommit(key, text, token)
	var tree := Engine.get_main_loop() as SceneTree
	var result := ""
	while result == "":
		await tree.process_frame
		result = str(JavaScriptBridge.eval("window.ironLegacyIdbTake('%s')" % token, true))
	return result
