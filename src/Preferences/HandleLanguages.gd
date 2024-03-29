extends Node

const LANGUAGES_DICT := {
	"en_US": ["English", "English"],
	"cs_CZ": ["Czech", "Czech"],
	"da_DK": ["Dansk", "Danish"],
	"de_DE": ["Deutsch", "German"],
	"el_GR": ["Ελληνικά", "Greek"],
	"eo_UY": ["Esperanto", "Esperanto"],
	"es_ES": ["Español", "Spanish"],
	"fr_FR": ["Français", "French"],
	"id_ID": ["Indonesian", "Indonesian"],
	"it_IT": ["Italiano", "Italian"],
	"lv_LV": ["Latvian", "Latvian"],
	"pl_PL": ["Polski", "Polish"],
	"pt_BR": ["Português Brasileiro", "Brazilian Portuguese"],
	"pt_PT": ["Português", "Portuguese"],
	"ru_RU": ["Русский", "Russian"],
	"zh_CN": ["简体中文", "Chinese Simplified"],
	"zh_TW": ["繁體中文", "Chinese Traditional"],
	"nb_NO": ["Norsk Bokmål", "Norwegian Bokmål"],
	"hu_HU": ["Magyar", "Hungarian"],
	"ro_RO": ["Română", "Romanian"],
	"ko_KR": ["한국어", "Korean"],
	"tr_TR": ["Türkçe", "Turkish"],
	"ja_JP": ["日本語", "Japanese"],
	"uk_UA": ["Українська", "Ukrainian"],
}

var loaded_locales: PackedStringArray = LANGUAGES_DICT.keys()


func _ready() -> void:
	loaded_locales.sort()  # Make sure locales are always sorted
	var locale_index := -1
	var saved_locale := OS.get_locale()
	# Load language
	if Global.config_cache.has_section_key("preferences", "locale"):
		saved_locale = Global.config_cache.get_value("preferences", "locale")
		locale_index = loaded_locales.find(saved_locale)
	_set_locale(saved_locale)  # If no language is saved, OS' locale is used

	var button_group: ButtonGroup = $"System Language".button_group
	for locale in loaded_locales:  # Create radiobuttons for each language
		var button := CheckBox.new()
		button.text = LANGUAGES_DICT[locale][0] + " [%s]" % [locale]
		button.name = LANGUAGES_DICT[locale][1]
		button.tooltip_text = LANGUAGES_DICT[locale][1]
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.button_group = button_group
		add_child(button)
		button.pressed.connect(_on_Language_pressed.bind(button.get_index()))
	get_child(locale_index + 2).button_pressed = true  # Select the appropriate button


func _on_Language_pressed(index: int) -> void:
	var locale := OS.get_locale()
	if index > 1:
		locale = loaded_locales[index - 2]
	_set_locale(locale)
	Global.config_cache.set_value("preferences", "locale", TranslationServer.get_locale())
	Global.config_cache.save("user://cache.ini")

	# Update some UI elements with the new translations
	Tools.update_hint_tooltips()
	Global.preferences_dialog.list.clear()
	Global.preferences_dialog.add_tabs(true)


func _set_locale(locale: String) -> void:
	if TranslationServer.get_locale() == locale:
		return
	if not locale in TranslationServer.get_loaded_locales():
		var translation := load("res://Translations/%s.po" % locale)
		if is_instance_valid(translation) and translation is Translation:
			TranslationServer.add_translation(translation)
		Keychain.load_translation(locale)
	TranslationServer.set_locale(locale)
