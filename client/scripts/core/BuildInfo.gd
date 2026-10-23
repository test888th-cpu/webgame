extends Node
## Build and runtime identity, shared by the browser client and (later) the
## headless zone server export.
##
## Other systems ask BuildInfo instead of reading ProjectSettings or OS feature
## tags directly, so that the protocol handshake and logs report one version.

## Bumped whenever the client/server wire protocol changes incompatibly.
## The zone server rejects handshakes whose protocol version differs.
const PROTOCOL_VERSION := 1


func game_version() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func engine_version() -> String:
	var info := Engine.get_version_info()
	return "%d.%d.%d-%s" % [info.major, info.minor, info.patch, info.status]


func is_web() -> bool:
	return OS.has_feature("web")


func is_dedicated_server() -> bool:
	return OS.has_feature("dedicated_server") or DisplayServer.get_name() == "headless"


func summary() -> String:
	var platform := "web" if is_web() else OS.get_name().to_lower()
	return (
		"v%s protocol=%d engine=%s platform=%s"
		% [game_version(), PROTOCOL_VERSION, engine_version(), platform]
	)
