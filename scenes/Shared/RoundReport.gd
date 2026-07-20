extends Control
class_name RoundReport
## RoundReport.gd
##
## Shared "grade-marker" feedback panel used after every question, whichever
## wave or question shape it came from. Mirrors how AS92006 answers are
## actually graded: it always names which tier the student's answer sits at
## (Excellence / Merit / Achievement / Not Achieved) plus a short, honest
## tip - never just "correct" or "wrong".

signal continued

@onready var tier_label: Label = $Panel/Margin/VBox/TierLabel
@onready var principle_label: Label = $Panel/Margin/VBox/PrincipleLabel
@onready var message_label: RichTextLabel = $Panel/Margin/VBox/MessageLabel
@onready var tip_label: RichTextLabel = $Panel/Margin/VBox/TipLabel
@onready var continue_button: Button = $Panel/Margin/VBox/ContinueButton

const TIER_DISPLAY := {
	"excellence": "Excellence",
	"merit": "Merit",
	"achievement": "Achievement",
	"not_achieved": "Not Achieved (yet)",
}

func _ready() -> void:
	hide()
	continue_button.pressed.connect(_on_continue_pressed)

## principle is a single entry from principles.json (see ContentLoader.load_principles()).
func show_report(tier: String, principle: Dictionary, message: String, exam_wording: bool = false) -> void:
	tier_label.text = TIER_DISPLAY.get(tier, tier)
	principle_label.text = principle.get("name_en", "")
	var definition: String = principle.get("exam_wording", "") if exam_wording else principle.get("plain_definition", "")
	message_label.text = "%s\n\n%s" % [message, definition]
	tip_label.text = principle.get("not_achieved_tip", "") if tier == "not_achieved" else ""
	tip_label.visible = tip_label.text != ""
	show()

func _on_continue_pressed() -> void:
	hide()
	continued.emit()
