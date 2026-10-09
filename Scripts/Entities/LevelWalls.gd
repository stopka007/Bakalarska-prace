extends Node2D

## Hustý pás asteroidů po stranách obrazovky.
##
## Není to rovná zeď: velikost, otočení i rozestup jsou nepravidelné
## a z kamene je vidět jen kousek, zbytek je mimo záběr. Gravitaci nemají.
## Náraz je pořád prohra. Kamera se vodorovně nehýbe, takže pás zůstává na krajích.


const BIG_TEXTURE: Texture2D = preload("res://Textures/meteorBig.png")
const SMALL_TEXTURE: Texture2D = preload("res://Textures/meteorSmall.png")
const HAZARD_SCRIPT: Script = preload("res://Scripts/Entities/GravityHazard.gd")

## O kolik pás přesahuje start a černou díru [px].
@export var end_margin: float = 640.0

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	var level: Node = get_parent()
	var spawn: Node2D = level.get_node_or_null("Spawn") as Node2D
	var hole: Node2D = level.get_node_or_null("BlackHole") as Node2D
	if spawn == null or hole == null:
		push_warning("LevelWalls: level nemá Spawn nebo BlackHole.")
		return

	_rng.seed = hash(level.name)
	var y_from: float = spawn.position.y + end_margin
	var y_to: float = hole.position.y - end_margin
	_scatter_side(-1.0, y_from, y_to)
	_scatter_side(1.0, y_from, y_to)


## Jedna strana obrazovky. `side` je -1 vlevo a 1 vpravo.
func _scatter_side(side: float, y_from: float, y_to: float) -> void:
	var y: float = y_from
	while y >= y_to:
		var cluster: int = _rng.randi_range(2, 4)
		for _i in cluster:
			var y_pos: float = y + _rng.randf_range(-42.0, 42.0)
			_place(side, y_pos)
		y -= _rng.randf_range(36.0, 78.0)


func _place(side: float, y: float) -> void:
	var meteor := Sprite2D.new()
	var big: bool = _rng.randf() > 0.42
	meteor.texture = BIG_TEXTURE if big else SMALL_TEXTURE
	meteor.rotation = _rng.randf_range(0.0, TAU)
	meteor.scale = Vector2.ONE * _rng.randf_range(0.8, 1.2)

	var half_size: float = meteor.texture.get_width() * meteor.scale.x * 0.5
	# Viditelný je jen výstupek, většina textury je za okrajem obrazovky.
	var peek: float = _rng.randf_range(half_size * 0.12, half_size * 0.48)
	var screen_edge: float = _screen_half_width()
	meteor.position = Vector2(side * (screen_edge + half_size - peek), y)

	meteor.set_script(HAZARD_SCRIPT)
	meteor.set("gravity_enabled", false)
	meteor.set("body_mass", 500.0 if big else 50.0)
	add_child(meteor)
	meteor.set("gravity_enabled", false)


func _screen_half_width() -> float:
	return get_viewport().get_visible_rect().size.x * 0.5
