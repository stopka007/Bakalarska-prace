extends Label

## Jednoduchý diagnostický výpis stavu simulace.
## Slouží k ověření, že loď plynule zrychluje a že integrátor drží energii.


## Sledovaná loď.
@export var ship: Ship


func _ready() -> void:
	# Když odkaz není nastaven v inspektoru, dohledáme loď podle skupiny.
	if ship == null:
		ship = get_tree().get_first_node_in_group(Ship.GROUP_NAME) as Ship


func _process(_delta: float) -> void:
	if ship == null:
		text = "Loď není přiřazena."
		return

