extends CanvasLayer

## Obrazovka po vtažení do černé díry.
##
## Hra se zastaví. Continue načte další level, Quit vrátí hráče
## do hlavního menu (postup už je uložený).


@export_file("*.tscn") var menu_scene_path: String = "res://MainScenes/main_menu.tscn"

@onready var continue_button: Button = $Center/Menu/ContinueButton
@onready var quit_button: Button = $Center/Menu/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	LevelProgress.level_finished.connect(_on_level_finished)


func _on_level_finished() -> void:
	get_tree().paused = true
	visible = true
	var has_next: bool = LevelProgress.has_next_level()
	continue_button.visible = has_next
	if has_next:
		continue_button.grab_focus()
	else:
		quit_button.grab_focus()


func continue_to_next_level() -> void:
	get_tree().paused = false
	LevelProgress.continue_to_next_level()


func quit_to_menu() -> void:
	if menu_scene_path.is_empty():
		push_warning("LevelComplete: není nastavena cesta k menu.")
		return
	get_tree().paused = false
	LevelProgress.run_finished = false
	var error: Error = get_tree().change_scene_to_file(menu_scene_path)
	if error != OK:
		push_error("LevelComplete: scénu '%s' se nepodařilo načíst (chyba %d)." % [menu_scene_path, error])
