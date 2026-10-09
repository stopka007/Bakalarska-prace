extends Control

## Hlavní menu hry.
##
## Tlačítko Levels otevře seznam kol. Která jsou odemčená, řeší `LevelProgress`.


## Tlačítko, které po otevření menu dostane klávesový fokus.
@export var default_focus_button: Button = null

@onready var _main_box: Control = $Center/Menu
@onready var _levels_box: Control = $Center/Levels
@onready var _level_list: VBoxContainer = $Center/Levels/LevelList


func _ready() -> void:
	_show_main()


func _show_main() -> void:
	_levels_box.hide()
	_main_box.show()
	if default_focus_button != null:
		default_focus_button.grab_focus()


## Přepne na seznam levelů a obnoví zámek podle uloženého postupu.
func on_levels_pressed() -> void:
	_main_box.hide()
	_levels_box.show()
	_level_list.call("refresh")


func on_levels_back_pressed() -> void:
	_show_main()


## Ukončí aplikaci. V editoru tím skončí i spuštěná hra.
func on_quit_pressed() -> void:
	get_tree().quit()
