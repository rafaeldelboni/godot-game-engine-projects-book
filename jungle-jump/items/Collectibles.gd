extends Area2D

signal pickup

var type: String
var textures: Dictionary = {'cherry': 'res://assets/sprites/cherry.png',
                            'gem'   : 'res://assets/sprites/gem.png'}

func init(new_type: String, pos: Vector2) -> void:
  $Sprite.texture = load(textures[new_type])
  type = new_type
  position = pos

func calc_points(type_to_calc: String) -> int:
  match type_to_calc:
    'gem':
      return 5
    _:
      return 1

func _on_Collectible_body_entered(_body: Node) -> void:
  emit_signal('pickup', calc_points(type))
  queue_free()
