extends Node

## Postup hráče a seznam levelů.
##
## Autoload, takže stav přežije přepnutí scény. Splněná kola se zapisují
## do `user://progress.cfg` a po dalším spuštění hry zůstanou odemčená.
##
## Nový level = nová scéna + jeden řádek v `LEVELS`. Odemykání je vždy
## „předchozí kolo je splněné", první level je otevřený od začátku.


const SAVE_PATH: String = "user://progress.cfg"
const GAMEPLAY_SCENE: String = "res://MainScenes/gameplay.tscn"
const MENU_SCENE: String = "res://MainScenes/main_menu.tscn"

## Pořadí levelů. `title` je text tlačítka, `scene` je rozložení překážek.
const LEVELS: Array[Dictionary] = [
	{"title": "Level 1", "scene": "res://Levels/level_01.tscn"},
	{"title": "Level 2", "scene": "res://Levels/level_02.tscn"},
	{"title": "Level 3", "scene": "res://Levels/level_03.tscn"},
]

## Právě hraný level (0 = první).
var selected_index: int = 0

## Dokončené kolo už ukázalo obrazovku s volbou dalšího levelu.
var run_finished: bool = false

signal level_finished

var _completed: Array[bool] = []


func _ready() -> void:
	_completed.resize(LEVELS.size())
	_completed.fill(false)
	_load()


func level_count() -> int:
	return LEVELS.size()


func level_title(index: int) -> String:
	return str(LEVELS[index]["title"])


func current_scene_path() -> String:
	if selected_index < 0 or selected_index >= LEVELS.size():
		return ""
	return str(LEVELS[selected_index]["scene"])


func is_completed(index: int) -> bool:
	return index >= 0 and index < _completed.size() and _completed[index]


## První level je vždy otevřený, další až po splnění předchozího.
func is_unlocked(index: int) -> bool:
	if index < 0 or index >= LEVELS.size():
		return false
	if index == 0:
		return true
	return is_completed(index - 1)


func has_next_level() -> bool:
	return selected_index + 1 < LEVELS.size()


func button_label(index: int) -> String:
	var title: String = level_title(index)
	if not is_unlocked(index):
		return "%s (locked)" % title
	if is_completed(index):
		return "%s (done)" % title
	return title


## Načte herní scénu s vybraným levelem.
func start_level(index: int) -> void:
	if not is_unlocked(index):
		return
	selected_index = index
	run_finished = false
	get_tree().paused = false
	var error: Error = get_tree().change_scene_to_file(GAMEPLAY_SCENE)
	if error != OK:
		push_error("LevelProgress: scénu '%s' se nepodařilo načíst (chyba %d)." % [GAMEPLAY_SCENE, error])


## Označí aktuální kolo za splněné, uloží postup a oznámí to menu.
func complete_current_level() -> void:
	if run_finished:
		return
	if selected_index >= 0 and selected_index < _completed.size():
		_completed[selected_index] = true
		_save()
	run_finished = true
	level_finished.emit()


func continue_to_next_level() -> void:
	if not has_next_level():
		return
	start_level(selected_index + 1)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var raw: Variant = config.get_value("progress", "completed", [])
	if typeof(raw) != TYPE_ARRAY:
		return
	var saved: Array = raw
	for index in mini(saved.size(), _completed.size()):
		_completed[index] = bool(saved[index])


func _save() -> void:
	var config := ConfigFile.new()
	var flags: Array[int] = []
	for done in _completed:
		flags.append(1 if done else 0)
	config.set_value("progress", "completed", flags)
	config.save(SAVE_PATH)
