class_name GravityField
extends RefCounted

## Výpočet gravitačního zrychlení v daném bodě od všech zdrojů gravitace.
##
## Newtonův gravitační zákon:  F = G * m1 * m2 / r^2
## Zrychlení testovací částice na hmotnosti nezávisí (a = F / m2):
##     a = G * M * r_vec / |r|^3
##
## Aby výpočet nedivergoval při r -> 0 (blízký průlet, kolize), používáme
## Plummerovo změkčení s parametrem epsilon:
##     a = G * M * r_vec / (|r|^2 + epsilon^2)^(3/2)
## Tento tvar odpovídá spojitému potenciálu, a proto (na rozdíl od naivního
## dosazení epsilon jen do jmenovatele velikosti síly) neporušuje zachování
## energie – to je podstatné pro srovnávání integrátorů.
##
## Třída je čistě statická a bez vazby na scénu, takže se stejný výpočet dá
## použít pro pohyb lodi i pro predikci trajektorie.


## Vyzvedne ze scény všechny aktivní zdroje gravitace.
## Volat ideálně jednou za snímek – výsledek pak předávat do `acceleration_at`,
## protože integrátory volají zrychlení až 4x za krok.
static func gather_bodies(tree: SceneTree) -> Array[GravityBody]:
	var bodies: Array[GravityBody] = []
	if tree == null:
		return bodies
	for node in tree.get_nodes_in_group(GravityBody.GROUP_NAME):
		var body := node as GravityBody
		if body != null and body.gravity_enabled:
			bodies.append(body)
	return bodies


## Celkové gravitační zrychlení v bodě `position` [px/s^2].
static func acceleration_at(bodies: Array[GravityBody], position: Vector2, gravitational_constant: float, softening: float) -> Vector2:
	var total: Vector2 = Vector2.ZERO
	var softening_squared: float = softening * softening

	for body in bodies:
		# Vektor od testovaného bodu ke středu tělesa (směr přitažlivé síly).
		var offset: Vector2 = body.global_position - position
		var distance_squared: float = offset.length_squared()

		# Těleso s omezeným dosahem vlivu přeskočíme.
		if body.influence_radius > 0.0 and distance_squared > body.influence_radius * body.influence_radius:
			continue

		# Ochrana pro případ vypnutého změkčení a nulové vzdálenosti.
		var denominator_base: float = distance_squared + softening_squared
		if denominator_base <= 0.0:
			continue

		# (r^2 + eps^2)^(3/2)
		var denominator: float = denominator_base * sqrt(denominator_base)
		total += gravitational_constant * body.body_mass * offset / denominator

	return total


## Gravitační potenciál na jednotku hmotnosti v bodě `position`.
## Změkčená (Plummerova) varianta: phi = -G * M / sqrt(r^2 + eps^2).
## Slouží k výpočtu celkové energie a tím k ověření kvality integrátoru.
static func specific_potential_at(bodies: Array[GravityBody], position: Vector2, gravitational_constant: float, softening: float) -> float:
	var potential: float = 0.0
	var softening_squared: float = softening * softening

	for body in bodies:
		var distance_squared: float = body.global_position.distance_squared_to(position)
		var denominator: float = sqrt(distance_squared + softening_squared)
		if denominator <= 0.0:
			continue
		potential -= gravitational_constant * body.body_mass / denominator

	return potential
