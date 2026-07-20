extends Control
## HotspotInterfacePanel.gd
##
## Reusable mock-interface renderer shared by every question shape in
## QuestionInterstitial. Builds a small fake app screen out of plain Godot
## Control nodes (Panel, Label, Button, ColorRect) from a JSON description -
## never a real screenshot, so there is no copyright/trademark issue - then
## lays an invisible clickable "hotspot" region on top of the feature being
## tested. Emits a signal when a hotspot is clicked; QuestionInterstitial
## decides what happens next.

signal hotspot_pressed(hotspot_index: int)

@onready var title_label: Label = $Background/Margin/Inner/TitleLabel
@onready var mock_root: Control = $Background/Margin/Inner/MockRoot

## Rebuilds the mock screen from a mock_interface dictionary (see
## content/README.md for the schema) and lays hotspot buttons on top.
func build(mock_interface: Dictionary, hotspots: Array = []) -> void:
	_clear()
	title_label.text = mock_interface.get("title", "")
	for element in mock_interface.get("elements", []):
		mock_root.add_child(_build_element(element))
	for i in hotspots.size():
		_add_hotspot(hotspots[i])

func _clear() -> void:
	for child in mock_root.get_children():
		child.queue_free()

func _build_element(el: Dictionary) -> Control:
	var rect: Array = el.get("rect", [0, 0, 100, 30])
	var type: String = el.get("type", "label")
	match type:
		"panel":
			var p := Panel.new()
			p.position = Vector2(rect[0], rect[1])
			p.size = Vector2(rect[2], rect[3])
			if el.has("text"):
				var l := Label.new()
				l.text = el["text"]
				l.set_anchors_preset(Control.PRESET_FULL_RECT)
				l.autowrap_mode = TextServer.AUTOWRAP_WORD
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				p.add_child(l)
			return p
		"button":
			var b := Button.new()
			b.text = el.get("text", "")
			b.position = Vector2(rect[0], rect[1])
			b.size = Vector2(rect[2], rect[3])
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE # decorative only
			return b
		"icon":
			var wrapper := Control.new()
			wrapper.position = Vector2(rect[0], rect[1])
			wrapper.size = Vector2(rect[2], rect[3])
			var cr := ColorRect.new()
			cr.color = Color(el.get("color", "#8fb8ac"))
			cr.set_anchors_preset(Control.PRESET_FULL_RECT)
			wrapper.add_child(cr)
			var icon_label := Label.new()
			icon_label.text = el.get("text", "")
			icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
			icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			wrapper.add_child(icon_label)
			return wrapper
		_:
			var label := Label.new()
			label.text = el.get("text", "")
			label.position = Vector2(rect[0], rect[1])
			label.size = Vector2(rect[2], rect[3])
			label.autowrap_mode = TextServer.AUTOWRAP_WORD
			if el.get("style", "") == "header":
				label.add_theme_font_size_override("font_size", 18)
			return label

func _add_hotspot(hotspot: Dictionary) -> void:
	var rect: Array = hotspot.get("rect", [0, 0, 40, 40])
	var index: int = mock_root.get_child_count()
	var btn := Button.new()
	btn.position = Vector2(rect[0], rect[1])
	btn.size = Vector2(rect[2], rect[3])
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(1, 1, 1, 0.0)
	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.93, 0.78, 0.35, 0.18)
	style_hover.border_color = Color(0.93, 0.78, 0.35, 0.95)
	style_hover.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	btn.pressed.connect(func(): hotspot_pressed.emit(index))
	mock_root.add_child(btn)
