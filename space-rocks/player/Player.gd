extends RigidBody2D

signal dead
signal shoot
signal lives_changed

export (PackedScene) var Bullet
export (float) var fire_rate

export (int) var engine_power
export (int) var spin_power

var body_inertia = 450
var thrust = Vector2()
var rotation_dir = 0

var can_shoot = true

enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = null

var screensize = Vector2()

var lives = 0 setget set_lives

func set_lives(value):
  lives = value
  emit_signal("lives_changed", lives)

func start():
  change_state(ALIVE)
  $Sprite.show()
  self.lives = 3

func change_state(new_state):
  match new_state:
    INIT:
      print('init')
      $CollisionShape2D.set_deferred("disabled", true)
      $Sprite.modulate.a = 0.5
    ALIVE:
      print('alive')
      $CollisionShape2D.set_deferred("disabled", false)
      $Sprite.modulate.a = 1.0
    INVULNERABLE:
      print('invulnerable')
      $CollisionShape2D.set_deferred("disabled", true)
      $Sprite.modulate.a = 0.5
      $InvulnerabilityTimer.start()
    DEAD:
      print('dead')
      $CollisionShape2D.set_deferred("disabled", true)
      $Sprite.hide()
      linear_velocity = Vector2()
      emit_signal("dead")
  self.set_deferred("state", new_state)

func shoot():
  if state == INVULNERABLE:
    return
  emit_signal("shoot", Bullet, $Muzzle.global_position, rotation)
  can_shoot = false
  $GunTimer.start()

func get_input():
  thrust = Vector2()
  if state in [DEAD, INIT]:
    return
  if Input.is_action_pressed("thrust"):
    thrust = Vector2(engine_power, 0)
  rotation_dir = 0
  if Input.is_action_pressed("rotate_right"):
    rotation_dir += 1
  if Input.is_action_pressed("rotate_left"):
    rotation_dir -= 1
  if Input.is_action_pressed("shoot") and can_shoot:
    shoot()

func _ready():
  screensize = get_viewport().get_visible_rect().size
  change_state(INIT)
  $GunTimer.wait_time = fire_rate

func _process(_delta):
  get_input()

func _integrate_forces(physics_state):
  set_inertia(body_inertia)
  set_applied_force(thrust.rotated(rotation))
  set_applied_torque(spin_power * rotation_dir)
  var xform = physics_state.get_transform()
  if state == INIT:
    xform.origin.x = 500
    xform.origin.y = 300
  else:
    if xform.origin.x > screensize.x:
      xform.origin.x = 0
    if xform.origin.x < 0:
      xform.origin.x = screensize.x
    if xform.origin.y > screensize.y:
      xform.origin.y = 0
    if xform.origin.y < 0:
      xform.origin.y = screensize.y
  physics_state.set_transform(xform)

func _on_GunTimer_timeout():
  can_shoot = true

func _on_InvulnerabilityTimer_timeout():
  change_state(ALIVE)

func _on_AnimationPlayer_animation_finished(_anim_name):
  $Explosion.hide()
  if state == DEAD:
    change_state(INIT)

func _on_Player_body_entered(body):
  if body.is_in_group('rocks'):
    body.explode()
    $Explosion.show()
    $Explosion/AnimationPlayer.play("explosion")
    self.lives -= 1
    if lives <= 0:
      change_state(DEAD)
    else:
      change_state(INVULNERABLE)
