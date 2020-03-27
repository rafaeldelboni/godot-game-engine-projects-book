extends RigidBody2D

signal dead
signal shoot
signal lives_changed
signal shield_changed

export (PackedScene) var Bullet
export (float) var fire_rate

export (int) var engine_power
export (int) var spin_power

export (int) var max_shield
export (float) var shield_regen

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
  self.shield = max_shield
  emit_signal("lives_changed", lives)

func take_damage(value):
  self.lives -= value
  $Explosion.show()
  $Explosion/AnimationPlayer.play("explosion")
  if lives <= 0:
    change_state(DEAD)
  else:
    change_state(INVULNERABLE)

var shield = 0 setget set_shield

func set_shield(value):
  if value > max_shield:
    value = max_shield
  shield = value
  emit_signal("shield_changed", self.shield / max_shield)
  if shield <= 0:
    take_damage(1)

func start():
  change_state(ALIVE)
  $Sprite.show()
  self.shield = max_shield
  self.lives = 3

func change_state(new_state):
  match new_state:
    INIT:
      $CollisionShape2D.set_deferred("disabled", true)
      $Sprite.modulate.a = 0.5
    ALIVE:
      $CollisionShape2D.set_deferred("disabled", false)
      $Sprite.modulate.a = 1.0
    INVULNERABLE:
      $CollisionShape2D.set_deferred("disabled", true)
      $Sprite.modulate.a = 0.5
      $InvulnerabilityTimer.start()
    DEAD:
      $EngineSound.stop()
      $CollisionShape2D.set_deferred("disabled", true)
      $Sprite.hide()
      linear_velocity = Vector2()
      emit_signal("dead")
  self.set_deferred("state", new_state)

func shoot():
  $LaserSound.play()
  if state == INVULNERABLE:
    return
  emit_signal("shoot", Bullet, $Muzzle.global_position, rotation)
  can_shoot = false
  $GunTimer.start()

func get_input():
  thrust = Vector2()
  $Exhaust.emitting = false
  if state in [DEAD, INIT]:
    return
  if Input.is_action_pressed("thrust"):
    $Exhaust.emitting = true
    thrust = Vector2(engine_power, 0)
    if not $EngineSound.playing:
      $EngineSound.play()
  else:
    $EngineSound.stop()
  rotation_dir = 0
  if Input.is_action_pressed("rotate_right"):
    rotation_dir += 1
  if Input.is_action_pressed("rotate_left"):
    rotation_dir -= 1
  if Input.is_action_pressed("shoot") and can_shoot:
    shoot()

func _ready():
  screensize = get_viewport().get_visible_rect().size
  self.shield = max_shield
  change_state(INIT)
  $GunTimer.wait_time = fire_rate

func _process(delta):
  self.shield += shield_regen * delta
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
    self.shield -= body.size * 25
