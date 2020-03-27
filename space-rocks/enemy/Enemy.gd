extends Area2D

signal shoot
signal exploded

export (PackedScene) var Bullet
export (int) var speed
export (int) var health

var follow
var target = null

func shoot():
  $LaserSound.play()
  var dir = target.global_position - global_position
  dir = dir.rotated(rand_range(-0.1, 0.1)).angle()
  emit_signal('shoot', Bullet, global_position, dir)

func shoot_pulse(n, delay):
  for _i in range(n):
    shoot()
    yield(get_tree().create_timer(delay), 'timeout')

func explode():
  speed = 0
  $GunTimer.stop()
  $CollisionShape2D.disabled = true
  $Sprite.hide()
  $Explosion.show()
  $Explosion/AnimationPlayer.play('explosion')
  emit_signal("exploded")

func take_damage(amount):
  health -= amount
  $AnimationPlayer.play('flash')
  if health <= 0:
    explode()
  yield($AnimationPlayer, 'animation_finished')

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
  if follow.unit_offset >= 1:
    queue_free()

func _on_AnimationPlayer_animation_finished(_animation):
  queue_free()

func _on_GunTimer_timeout():
  shoot_pulse(3, 0.15)

func _on_Enemy_body_entered(body):
  if body.name == 'Player':
    body.shield -= 50
    explode()
