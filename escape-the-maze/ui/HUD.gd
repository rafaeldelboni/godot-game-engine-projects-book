extends CanvasLayer

func update_score_label():
  $MarginContainer/ScoreLabel.text = str(Global.score)

func update_score(value):
  Global.score += value
  update_score_label()

func _ready():
  update_score_label()
