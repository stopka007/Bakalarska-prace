class_name GravityHazard
extends GravityBody

## Zdroj gravitace, který je zároveň smrtelnou překážkou.
##
## Skript je záměrně nezávislý na konkrétní textuře. Přihodíš ho v editoru
## na libovolný `Sprite2D` (nebo jiný `Node2D` se sprite potomkem) a objekt
## se zaregistruje jako gravitační těleso (`GravityBody`) a dostane kolizní
## `Area2D`. Loď už `Area2D` má – při nárazu se hra vrátí do hlavního menu.
##
## `GravityField` se nepoužívá jako komponenta na objekt: to je jen výpočet
## zrychlení. Tento skript rozšiřuje `GravityBody`, odkud gravitaci bere.


## Scéna, na kterou se přepne po nárazu lodi.
@export_file("*.tscn") var menu_scene_path: String = "res://MainScenes/main_menu.tscn"

## Vypnutím objekt gravitaci dál působí, ale náraz už hru neukončí.
@export var lethal_on_contact: bool = true

## Kolizní poloměr [px]. 0 = spočítat z textury (polovina delší strany).
@export_range(0.0, 2000.0, 1.0, "or_greater") var collision_radius: float = 0.0

## Škálování automatického poloměru (1 = opsaná kružnice kolem textury).
@export_range(0.1, 2.0, 0.05) var collision_scale: float = 0.9


# Zámek, aby se scéna při trvajícím překryvu nepřepínala opakovaně.
var _returning_to_menu: bool = false


func _ready() -> void:
	super._ready()
	_setup_collision()


## Doplní (nebo znovupoužije) Area2D s kruhovou kolizí a napojí signály.
func _setup_collision() -> void:
	var area: Area2D = _resolve_area()
	area.monitoring = true
	area.monitorable = true

	var shape_node: CollisionShape2D = _resolve_shape(area)
	var circle: CircleShape2D = shape_node.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		shape_node.shape = circle
	circle.radius = _compute_radius()

	if not area.area_entered.is_connected(_on_area_entered):
		area.area_entered.connect(_on_area_entered)
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)


## Když je skript na Area2D, použije ji. Jinak vytvoří potomka `HazardArea`.
func _resolve_area() -> Area2D:
	# Přes Node, protože parser neví, že skript může viset na Area2D/Sprite2D.
	var node: Node = self
	if node is Area2D:
		return node as Area2D

	var existing: Area2D = get_node_or_null("HazardArea") as Area2D
	if existing != null:
		return existing

	var area := Area2D.new()
	area.name = "HazardArea"
	add_child(area)
	return area


## Najde existující CollisionShape2D, nebo ho vytvoří.
func _resolve_shape(area: Area2D) -> CollisionShape2D:
	for child in area.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D

	var shape_node := CollisionShape2D.new()
	shape_node.name = "CollisionShape2D"
	area.add_child(shape_node)
	return shape_node


## Poloměr z inspektoru, případně z textury sprite uzel.
func _compute_radius() -> float:
	if collision_radius > 0.0:
		return collision_radius

	var sprite: Sprite2D = _find_sprite()
	if sprite == null or sprite.texture == null:
		return maxf(surface_radius, 8.0)

	var size: Vector2 = sprite.texture.get_size() * sprite.scale.abs()
	return maxf(size.x, size.y) * 0.5 * collision_scale


## Sprite může být samotný uzel se skriptem, nebo jeho potomek.
func _find_sprite() -> Sprite2D:
	# Přes Node, protože parser neví, že skript může viset na Sprite2D.
	var node: Node = self
	if node is Sprite2D:
		return node as Sprite2D
	for child in get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null


func _on_area_entered(area: Area2D) -> void:
	if _is_player(area):
		_return_to_menu()


func _on_body_entered(body: Node2D) -> void:
	if _is_player(body):
		_return_to_menu()


func _is_player(node: Node) -> bool:
	if node == null:
		return false
	return node is Ship or node.is_in_group(Ship.GROUP_NAME)


## Náraz zahodí rozehranou hru a vrátí hráče do hlavního menu.
func _return_to_menu() -> void:
	if not lethal_on_contact or _returning_to_menu:
		return
	if menu_scene_path.is_empty():
		push_warning("GravityHazard: není nastavena cesta ke scéně menu.")
		return

	_returning_to_menu = true
	# Pauza z Escape menu by jinak mohla nechat strom zmrazený i po přepnutí.
	get_tree().paused = false

	var error: Error = get_tree().change_scene_to_file(menu_scene_path)
	if error != OK:
		_returning_to_menu = false
		push_error("GravityHazard: scénu '%s' se nepodařilo načíst (chyba %d)." % [menu_scene_path, error])
