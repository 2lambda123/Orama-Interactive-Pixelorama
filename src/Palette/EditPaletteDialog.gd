extends ConfirmationDialog

# Emitted when user confirms their changes
signal saved(name, comment, width, height)
signal deleted
signal exported(path)

const EXPORT_ACTION := "export"
const DELETE_ACTION := "delete"
const BIN_ACTION := "trash"

# Keeps original size of edited palette
var origin_width := 0
var origin_height := 0

var old_name := ""

onready var name_input := $VBoxContainer/PaletteMetadata/Name
onready var comment_input := $VBoxContainer/PaletteMetadata/Comment
onready var width_input := $VBoxContainer/PaletteMetadata/Width
onready var height_input := $VBoxContainer/PaletteMetadata/Height
onready var path_input := $VBoxContainer/PaletteMetadata/Path

onready var size_reduced_warning := $VBoxContainer/SizeReducedWarning
onready var already_exists_warning := $VBoxContainer/AlreadyExistsWarning
onready var delete_confirmation := $DeleteConfirmation
onready var export_file_dialog: FileDialog = $ExportFileDialog


func _ready() -> void:
	# Add delete and export buttons to edit palette dialog
	add_button(tr("Delete"), false, DELETE_ACTION)
	add_button(tr("Export"), false, EXPORT_ACTION)
	delete_confirmation.get_ok().text = tr("Delete Permanently")
	delete_confirmation.add_button(tr("Move to Trash"), false, BIN_ACTION)


func open(current_palette: Palette) -> void:
	if current_palette:
		name_input.text = current_palette.name
		comment_input.text = current_palette.comment
		width_input.value = current_palette.width
		height_input.value = current_palette.height
		path_input.text = current_palette.resource_path
		export_file_dialog.current_file = current_palette.name

		# Store original size so it can be compared with changed values
		# and warning can be shown if it is reduced
		origin_width = current_palette.width
		origin_height = current_palette.height
		toggle_size_reduced_warning(false)

		# Hide warning
		old_name = current_palette.name
		toggle_already_exists_warning(false)

		# Stop all inputs in the rest of the app
		Global.dialog_open(true)
		popup_centered()


# Shows/hides a warning when palette size is being reduced
func toggle_size_reduced_warning(visible: bool) -> void:
	size_reduced_warning.visible = visible
	# Required to resize window to correct size if warning causes content overflow
	rect_size = rect_size


# Shows/hides a warning when palette already exists
func toggle_already_exists_warning(visible: bool) -> void:
	already_exists_warning.visible = visible

	# Disable confirm button so user cannot save
	get_ok().disabled = visible

	# Required to resize window to correct size if warning causes content overflow
	rect_size = rect_size


func _on_EditPaletteDialog_popup_hide() -> void:
	Global.dialog_open(false)


func _on_EditPaletteDialog_confirmed() -> void:
	emit_signal("saved", name_input.text, comment_input.text, width_input.value, height_input.value)


func _on_EditPaletteDialog_custom_action(action: String) -> void:
	if action == DELETE_ACTION:
		delete_confirmation.popup_centered()
	elif action == EXPORT_ACTION:
		export_file_dialog.popup_centered()


func _on_delete_confirmation_confirmed() -> void:
	emit_signal("deleted", true)
	delete_confirmation.hide()
	hide()


func _on_delete_confirmation_custom_action(action: String) -> void:
	if action == BIN_ACTION:
		emit_signal("deleted", false)
		delete_confirmation.hide()
		hide()


func _on_size_value_changed(_value):
	# Toggle resize warning label if palette size was reduced
	var size_decreased: bool = (
		height_input.value < origin_height
		or width_input.value < origin_width
	)
	toggle_size_reduced_warning(size_decreased)


func _on_Name_text_changed(new_name):
	if old_name != new_name:
		if Palettes.does_palette_exist(new_name):
			toggle_already_exists_warning(true)
		else:
			toggle_already_exists_warning(false)

		# Disable ok button on empty name
		if new_name == "":
			get_ok().disabled = true


func _on_ExportFileDialog_file_selected(path: String) -> void:
	emit_signal("exported", path)
