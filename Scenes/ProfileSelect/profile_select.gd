extends Control
## profile_select.gd
##
## Profile management: list, create, delete, and select profiles.
## Flow: Select profile → Cafe Hub.

@onready var profile_list: ItemList = $Panel/VBox/ProfileList
@onready var new_name_edit: LineEdit = $Panel/VBox/NewProfileHBox/NameEdit
@onready var create_btn: Button = $Panel/VBox/NewProfileHBox/CreateBtn
@onready var play_btn: Button = $Panel/VBox/ButtonHBox/PlayBtn
@onready var delete_btn: Button = $Panel/VBox/ButtonHBox/DeleteBtn
@onready var back_btn: Button = $Panel/VBox/ButtonHBox/BackBtn
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var confirm_panel: Panel = $ConfirmPanel
@onready var confirm_label: Label = $ConfirmPanel/VBox/ConfirmLabel
@onready var confirm_yes_btn: Button = $ConfirmPanel/VBox/HBox/YesBtn
@onready var confirm_no_btn: Button = $ConfirmPanel/VBox/HBox/NoBtn

## Currently selected profile name.
var _selected_name: String = ""


func _ready() -> void:
	create_btn.pressed.connect(_on_create_pressed)
	play_btn.pressed.connect(_on_play_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	confirm_yes_btn.pressed.connect(_on_confirm_delete)
	confirm_no_btn.pressed.connect(_on_cancel_delete)
	profile_list.item_selected.connect(_on_profile_selected)
	new_name_edit.text_submitted.connect(_on_name_submitted)

	confirm_panel.visible = false
	play_btn.disabled = true
	delete_btn.disabled = true
	_refresh_list()


## Refreshes the profile list from SaveManager.
func _refresh_list() -> void:
	profile_list.clear()
	_selected_name = ""
	play_btn.disabled = true
	delete_btn.disabled = true

	var names := SaveManager.list_profiles()
	for profile_name in names:
		profile_list.add_item(profile_name)

	if names.size() == 0:
		status_label.text = "No profiles yet. Create one to begin!"
	else:
		status_label.text = "Select a profile to play."


## Called when a profile is selected in the list.
func _on_profile_selected(index: int) -> void:
	_selected_name = profile_list.get_item_text(index)
	play_btn.disabled = false
	delete_btn.disabled = false
	status_label.text = "Selected: %s" % _selected_name


## Creates a new profile.
func _on_create_pressed() -> void:
	var player_name := new_name_edit.text.strip_edges()
	if player_name == "":
		status_label.text = "Please enter a name."
		return

	if player_name.length() > 20:
		status_label.text = "Name too long (max 20 characters)."
		return

	var profile := SaveManager.create_profile(player_name)
	if profile == null:
		status_label.text = "Profile '%s' already exists." % player_name
		return

	new_name_edit.text = ""
	status_label.text = "Created profile: %s" % player_name
	_refresh_list()

	# Auto-select the new profile
	for i in profile_list.item_count:
		if profile_list.get_item_text(i) == player_name:
			profile_list.select(i)
			_on_profile_selected(i)
			break


## Shortcut: pressing Enter in the name field creates the profile.
func _on_name_submitted(_text: String) -> void:
	_on_create_pressed()


## Loads the selected profile and transitions to the Cafe Hub.
func _on_play_pressed() -> void:
	if _selected_name == "":
		return

	var profile := SaveManager.load_profile(_selected_name)
	if profile == null:
		status_label.text = "Error loading profile."
		return

	GameController.set_profile(profile)
	AudioManager.apply_profile_settings(profile)
	SRSEngine.load_cards_for_profile(profile)

	play_btn.disabled = true
	GameController.change_scene("res://Scenes/CafeHub/cafe_hub.tscn")


## Shows delete confirmation dialog.
func _on_delete_pressed() -> void:
	if _selected_name == "":
		return
	confirm_label.text = "Delete profile '%s'?\nThis cannot be undone." % _selected_name
	confirm_panel.visible = true


## Confirms profile deletion.
func _on_confirm_delete() -> void:
	confirm_panel.visible = false
	SaveManager.delete_profile(_selected_name)
	status_label.text = "Deleted profile: %s" % _selected_name
	_refresh_list()


## Cancels profile deletion.
func _on_cancel_delete() -> void:
	confirm_panel.visible = false


## Returns to the title screen.
func _on_back_pressed() -> void:
	GameController.change_scene("res://Scenes/TitleScreen/title_screen.tscn")
