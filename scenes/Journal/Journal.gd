extends Control
## Journal.gd
##
## Ono's little notebook - opened from the "Open Journal" button on the Hub
## screen instead of a dashboard menu. Draws a simple bar chart of mastery
## per usability concept using Godot's own 2D drawing (no plugins needed),
## styled as a quiet page of notes rather than an analytics screen. Reads
## straight from ProgressTracker, so this is always exactly what's saved.

@onready var chart_area: Control = $Margin/VBox/Scroll/ChartArea
@onready var back_button: Button = $BackButton

const ROW_HEIGHT := 26.0
const LABEL_WIDTH := 300.0
const CHART_WIDTH := 340.0

var _names: Dictionary = {}

func _ready() -> void:
	_names = {}
	for pid in ProgressTracker.PRINCIPLE_IDS:
		_names[pid] = pid.capitalize()
	for p in ContentLoader.load_principles().values():
		_names[p["id"]] = p.get("name_en", p["id"])
	back_button.pressed.connect(_on_back_pressed)
	chart_area.draw.connect(_draw_chart)
	var rows := ProgressTracker.PRINCIPLE_IDS.size()
	chart_area.custom_minimum_size = Vector2(LABEL_WIDTH + CHART_WIDTH + 40.0, rows * ROW_HEIGHT + 20.0)
	chart_area.queue_redraw()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Hub/Hub.tscn")

func _draw_chart() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 14
	var y := 14.0
	for pid in ProgressTracker.PRINCIPLE_IDS:
		var mastery: int = ProgressTracker.get_mastery(pid)
		var label_text: String = _names.get(pid, pid)
		chart_area.draw_string(font, Vector2(0.0, y + 15.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, LABEL_WIDTH, font_size)
		var track_rect := Rect2(LABEL_WIDTH + 10.0, y, CHART_WIDTH, ROW_HEIGHT - 8.0)
		chart_area.draw_rect(track_rect, Color(0.55, 0.5, 0.4, 0.25))
		var fill_width: float = CHART_WIDTH * (float(mastery) / 100.0)
		var fill_rect := Rect2(LABEL_WIDTH + 10.0, y, fill_width, ROW_HEIGHT - 8.0)
		chart_area.draw_rect(fill_rect, Color(0.93, 0.78, 0.35, 0.9))
		y += ROW_HEIGHT
