extends VBoxContainer

## Seznam levelů v hlavním menu. Zamčené kolo nejde spustit,
## splněné zůstane označené i po restartu hry.


func refresh() -> void:
	for child in get_children():
		child.free()

	var first_open: Button = null
	for index in LevelProgress.level_count():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 48)
		button.add_theme_font_size_override("font_size", 20)
		button.text = LevelProgress.button_label(index)
		button.disabled = not LevelProgress.is_unlocked(index)
		if not button.disabled:
			button.pressed.connect(_on_level_pressed.bind(index))
			if first_open == null:
				first_open = button
		add_child(button)

	if first_open != null:
		first_open.grab_focus()


func _on_level_pressed(index: int) -> void:
	LevelProgress.start_level(index)
