extends CanvasLayer
## On-screen interface: hero HP/energy/XP, level, coins, area, the tracked
## quest, a boss health bar during boss fights, and short notifications.

const BAR_WIDTH := 120.0
const TOAST_SECONDS := 2.2

var zone: ZoneSim
var profile: PlayerProfile
var content: ContentDB

var _toast_left := 0.0

@onready var _status: Label = $Status
@onready var _hp_fill: ColorRect = $Bars/HpFill
@onready var _energy_fill: ColorRect = $Bars/EnergyFill
@onready var _xp_fill: ColorRect = $Bars/XpFill
@onready var _info: Label = $Info
@onready var _quest: Label = $Quest
@onready var _boss: Control = $Boss
@onready var _boss_name: Label = $Boss/Name
@onready var _boss_fill: ColorRect = $Boss/Fill
@onready var _toast: Label = $Toast
@onready var _touch: Control = $Touch


func _ready() -> void:
	$Build.text = BuildInfo.summary()
	# Touch buttons only appear on touch devices; desktop players never see them.
	_touch.visible = DisplayServer.is_touchscreen_available()
	_toast.visible = false


func attach(p_zone: ZoneSim, p_profile: PlayerProfile, p_content: ContentDB) -> void:
	zone = p_zone
	profile = p_profile
	content = p_content


func toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast_left = TOAST_SECONDS


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	if zone == null:
		return
	var hero := zone.hero
	_hp_fill.size.x = BAR_WIDTH * hero.hp / hero.max_hp
	_energy_fill.size.x = BAR_WIDTH * hero.energy / CombatRules.MAX_ENERGY
	_xp_fill.size.x = BAR_WIDTH * profile.xp / maxi(1, profile.xp_to_next(content))
	_info.text = (
		"Lv %d   HP %d/%d   Coins %d   %s"
		% [profile.level, hero.hp, hero.max_hp, profile.money, zone.area.get("name", "")]
	)
	_quest.text = _tracked_quest()
	var boss := zone.fighter(zone.boss_id) if zone.boss_id else null
	_boss.visible = boss != null and not boss.is_ko()
	if _boss.visible:
		_boss_name.text = str(content.enemy(boss.kind).get("name", ""))
		_boss_fill.size.x = 300.0 * boss.hp / boss.max_hp
	_status.text = "%s  |  %d fps" % [hero.state_name(), Engine.get_frames_per_second()]


func _tracked_quest() -> String:
	for quest_id: String in profile.quests:
		var entry: Dictionary = profile.quests[quest_id]
		var quest: Dictionary = content.quests[quest_id]
		if entry["state"] == "active":
			return "%s  %d/%d" % [quest["name"], entry["progress"], quest["objective"]["count"]]
		if entry["state"] == "complete":
			return "%s  - hand in" % quest["name"]
	return ""
