extends Area2D

signal shoot

export (PackedScene) var Bullet
export (int) var speed
export (int) var health

var follow
var target = null

func _ready():
  $Sprite.frame = randi() % 3
  var num_path = randi() % $EnemyPath.get_child_count()
  var path = $EnemyPath.get_children()[num_path]
  follow = PathFollow2D.new()
  path.add_child(follow)
  follow.loop = false

func _process(delta):
  follow.offset += speed * delta
  position = follow.global_position
  if follow.unit_offset > 1:
    queue_free()

func _on_AnimationPlayer_animation_finished(_animation):
  queue_free()

func _on_GunTimer_timeout():
  pass
