extends GravityHazard

## Planeta pro výukové mise.
##
## Je to obyčejný zdroj gravitace (Newton / Plummer podle `GravityField`).
## Kroužek se kreslí kódem, textura není potřeba. `lethal_on_contact`
## zapni, když má dopad na povrch skončit prohrou (oběh, prak).
## Vypni ho, když je cílem mise na planetu dopadnout.


## Barva kotouče.
@export var planet_color: Color = Color(0.35, 0.62, 0.95)


func _ready() -> void:
	if collision_radius <= 0.0:
		collision_radius = surface_radius
	super._ready()
	z_index = 2
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, surface_radius * 1.18, planet_color.lightened(0.35))
	draw_circle(Vector2.ZERO, surface_radius, planet_color)
	draw_circle(Vector2.ZERO, surface_radius * 0.35, planet_color.darkened(0.25))
