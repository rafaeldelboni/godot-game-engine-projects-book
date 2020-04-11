extends Node

func _ready() -> void:
  # make sure level numbers are 2 digits ("01", etc.)
  var level_num: String = str(GameState.current_level).pad_zeros(2)
  var path: String = 'res://levels/Level-%s.tscn' % level_num
  var map: Node = load(path).instance()
  add_child(map)
