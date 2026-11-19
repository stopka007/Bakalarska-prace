extends PanelContainer

## Text právě hrané mise. Když level kartu nemá, panel se schová.


@onready var _title: Label = $Margin/Box/Title
@onready var _body: Label = $Margin/Box/Body


func _process(_delta: float) -> void:
	var card: Node = get_tree().get_first_node_in_group(&"mission_card")
	if card == null:
		visible = false
		return
	visible = true
	_title.text = str(card.get("mission_title"))
	_body.text = str(card.get("mission_text"))
