extends RigidBody2D

signal exploded

var screensize = Vector2()
var size
var radius
var scale_factor = 0.2

func start(pos, vel, _size):
  position = pos
  size = _size
  mass = 1.5 * size
  $Sprite.scale = Vector2(1, 1) * scale_factor * size
  $Explosion.scale = Vector2(0.5, 0.5) * size
  radius = int($Sprite.texture.get_size().x / 2 * scale_factor * size)
  var shape = CircleShape2D.new()
  shape.radius = radius
  $CollisionShape2D.shape = shape
  linear_velocity = vel
  angular_velocity = rand_range(-1.5, 1.5)

func explode():
  layers = 0
  $Sprite.hide()
  $Explosion/AnimationPlayer.play("explosion")
  emit_signal("exploded", size, radius, position, linear_velocity)
  linear_velocity = Vector2()
  angular_velocity = 0

func _integrate_forces(physics_state):
  var xform = physics_state.get_transform()
  var scr_radius_x = screensize.x + radius
  var scr_radius_y = screensize.y + radius
  if xform.origin.x > scr_radius_x:
    xform.origin.x = -radius
  if xform.origin.x < -radius:
    xform.origin.x = scr_radius_x
  if xform.origin.y > scr_radius_y:
    xform.origin.y = -radius
  if xform.origin.y < -radius:
    xform.origin.y = scr_radius_y
  physics_state.set_transform(xform)

func _on_AnimationPlayer_animation_finished(_anim_name):
  queue_free()
