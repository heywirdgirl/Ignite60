extends Node

@export var use_test_ads  : bool = true
@export var banner_on_top : bool = false

const ANDROID_REAL_ID : String = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
const IOS_REAL_ID     : String = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
const ANDROID_TEST_ID : String = "ca-app-pub-3940256099942544/6300978111"
const IOS_TEST_ID     : String = "ca-app-pub-3940256099942544/2934735716"
const CONFIG_PATH     : String = "user://ads_settings.cfg"

var ads_enabled : bool = true
var _ad_view    : AdView = null
var _is_mobile  : bool   = false

func _ready() -> void:
	_is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	_load_config()

	if not _is_mobile:
		push_warning("AdsManager: skipped, not on mobile.")
		return

	MobileAds.initialize()
	load_and_show_banner()

func load_and_show_banner() -> void:
	if not _is_mobile or not ads_enabled:
		return

	var unit_id : String = _get_unit_id()
	var position : int   = AdPosition.Values.TOP if banner_on_top \
	                       else AdPosition.Values.BOTTOM

	_ad_view = AdView.new(unit_id, AdSize.BANNER, position)
	_ad_view.load_ad(AdRequest.new())

func hide_banner() -> void:
	if _ad_view:
		_ad_view.hide()

func show_banner() -> void:
	if _ad_view and ads_enabled:
		_ad_view.show()

func remove_ads() -> void:
	ads_enabled = false
	if _ad_view:
		_ad_view.destroy()
		_ad_view = null
	_save_config()

func _get_unit_id() -> String:
	if use_test_ads:
		return ANDROID_TEST_ID if OS.get_name() == "Android" else IOS_TEST_ID
	return ANDROID_REAL_ID if OS.get_name() == "Android" else IOS_REAL_ID

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		ads_enabled = cfg.get_value("ads", "ads_enabled", true)

func _save_config() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ads", "ads_enabled", ads_enabled)
	cfg.save(CONFIG_PATH)
