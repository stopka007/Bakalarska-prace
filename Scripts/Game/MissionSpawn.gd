extends Marker2D

## Start mise. `LevelHost` odsud vezme počáteční rychlost a nádrž.
##
## Rychlost je ve světových pixelech za sekundu. Záporné Y je v Godotu nahoru.
## `fuel_capacity` < 0 nechá výchozí plnou nádrž lodi.


## Rychlost lodi hned po startu [px/s]. Nula znamená, že loď stojí.
@export var initial_velocity: Vector2 = Vector2.ZERO

## Velikost nádrže pro tuto misi. Záporné = nechat hodnotu z lodi.
@export var fuel_capacity: float = -1.0
