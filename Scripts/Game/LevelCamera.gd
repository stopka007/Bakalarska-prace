extends Camera2D

## Kamera drží vodorovnou pozici a sleduje loď jen dopředu a dozadu.
##
## Díky tomu pás asteroidů na krajích obrazovky zůstává na místě
## a loď se v záběru posouvá doleva a doprava.


## Světová souřadnice X, na které kamera stojí. Levely jsou stavěné kolem nuly.
@export var locked_x: float = 0.0


func _ready() -> void:
	# Bez vazby na transformaci lodi, jinak by se kamera točila a jezdila do stran.
	top_level = true
	_follow_ship()


func _physics_process(_delta: float) -> void:
	_follow_ship()


func _follow_ship() -> void:
	var ship: Node2D = get_parent() as Node2D
	if ship == null:
		return
	global_position = Vector2(locked_x, ship.global_position.y)
