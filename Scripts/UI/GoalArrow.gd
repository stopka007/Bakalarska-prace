extends Control

## Šipka na okraji obrazovky, když je cíl mimo záběr.
##
## Na obrazovce se nekreslí nic, dokud je cíl vidět. Jakmile zmizí,
## šipka sedí na kraji a míří k němu.


const EDGE_MARGIN: float = 36.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if LevelProgress.briefing or LevelProgress.run_finished:
		return
	var target: Node2D = _find_target()
	if target == null:
		return

	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return

	var screen: Vector2 = camera.get_canvas_transform() * target.global_position
	var view: Vector2 = size
	var center: Vector2 = view * 0.5
	var half: Vector2 = center - Vector2(EDGE_MARGIN, EDGE_MARGIN)
	var offset: Vector2 = screen - center

	if absf(offset.x) <= half.x and absf(offset.y) <= half.y:
		return

	var reach: float = 1.0
	if offset.x != 0.0:
		reach = minf(reach, half.x / absf(offset.x))
	if offset.y != 0.0:
		reach = minf(reach, half.y / absf(offset.y))

	var arrow_at: Vector2 = center + offset * reach
	draw_set_transform(arrow_at, offset.angle(), Vector2.ONE)
	draw_colored_polygon(
		PackedVector2Array([Vector2(16, 0), Vector2(-12, 9), Vector2(-12, -9)]),
		Color(0.45, 0.95, 0.75, 0.95)
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _find_target() -> Node2D:
	var goal: Node = get_tree().get_first_node_in_group(&"mission_goal")
	if goal is Node2D:
		return goal as Node2D
	var target: Node = get_tree().get_first_node_in_group(&"mission_target")
	if target is Node2D:
		return target as Node2D
	return null
