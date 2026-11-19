extends CanvasLayer

## Okno před misí. Hra stojí, dokud hráč nenapíše, že text četl.
##
## Volá ho `LevelHost` až po nastavení lodi, takže po startu
## už loď má správnou rychlost a nádrž.


@onready var _title: Label = $Center/Panel/Margin/Box/Title
@onready var _body: Label = $Center/Panel/Margin/Box/Body
@onready var _continue_button: Button = $Center/Panel/Margin/Box/ContinueButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


## Ukáže vysvětlení a zastaví simulaci.
func open_for(card: Node) -> void:
	_title.text = str(card.get("mission_title"))
	var lesson: String = str(card.get("lesson_text"))
	if lesson.is_empty():
		lesson = str(card.get("mission_text"))
	_body.text = lesson
	visible = true
	LevelProgress.briefing = true
	get_tree().paused = true
	_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	LevelProgress.briefing = false
	get_tree().paused = false
	visible = false
