class_name DurableSave
extends RefCounted
## Saves that report completion. SaveStore.save_player and GameSession.set_setting
## write user:// at once. On the web user:// lives in memory and Godot copies it to
## IndexedDB (IDBFS: database "/userfs", store FILE_DATA, keyed by absolute path)
## in the background, measured at several seconds behind a write and longer under
## load, so a reload in that window would lose the write.
##
## persisted() therefore commits the file itself: it writes the text just written
## into the same IDBFS record Godot restores from at start (with the parent folders'
## records if missing) in one readwrite transaction, and reports success only on that
## transaction's oncomplete; onerror or onabort report failure. Godot's own later
## copy writes the same or newer text, never older. Off the web a closed file is
## already on disk.

## The page-side writer, installed once.
const JS := """
window.ironLegacyIdbResults = {};
window.ironLegacyIdbTake = function (t) {
	var r = window.ironLegacyIdbResults[t] || '';
	if (r) { delete window.ironLegacyIdbResults[t]; }
	return r;
};
window.ironLegacyIdbCommit = function (key, text, t) {
	var done = function (r) { window.ironLegacyIdbResults[t] = r; };
	var open = indexedDB.open('/userfs');
	open.onerror = function () { done('error'); };
	open.onsuccess = function () {
		var db = open.result;
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
			tx.oncomplete = function () { db.close(); done('ok'); };
			tx.onerror = function () { done('error'); };
			tx.onabort = function () { db.close(); done('error'); };
		} catch (err) { db.close(); done('error'); }
	};
};
"""

static var _ready := false
static var _token := 0


## Save `state` (SaveStore.save_player) and wait until it is durable.
static func save_player(state: Dictionary, seconds := 10.0) -> bool:
	if not SaveStore.save_player(state):
		return false
	var path := SaveStore.player_folder().path_join(str(state["id"]) + ".json")
	return await persisted(path, seconds)


## Make `path` durable now: off the web it already is; on the web, commit its
## current text to the IDBFS record. True only on the transaction's completion.
## Commits run in the order asked, so the last one holds the latest text.
static func persisted(path: String, seconds := 10.0) -> bool:
	if not OS.has_feature("web"):
		return true
	_install()
	var key := ProjectSettings.globalize_path(path)
	var text := FileAccess.get_file_as_string(path)
	_token += 1
	var token := str(_token)
	var window := JavaScriptBridge.get_interface("window")
	window.ironLegacyIdbCommit(key, text, token)
	var tree := Engine.get_main_loop() as SceneTree
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	var result := ""
	while result == "" and Time.get_ticks_msec() < deadline:
		await tree.process_frame
		result = str(JavaScriptBridge.eval("window.ironLegacyIdbTake('%s')" % token, true))
	if result != "ok":
		push_error("save not committed to the browser store (%s): %s" % [result, path])
	return result == "ok"


static func _install() -> void:
	if _ready:
		return
	_ready = true
	JavaScriptBridge.eval(JS, true)
