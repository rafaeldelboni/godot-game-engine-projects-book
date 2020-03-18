extends RigidBody2D

signal shoot

export (PackedScene) var Bullet
export (float) var fire_rate

export (int) var engine_power
export (int) var spin_power

var thrust = Vector2()
var rotation_dir = 0

var can_shoot = true

enum {INIT, ALIVE, INVULNERABLE, DEAD}
var state = null

var screensize = Vector2()

func change_state(new_state):
  match new_state:
    INIT:
      $CollisionShape2D.disabled = true
    ALIVE:
      $CollisionShape2D.disabled = false
    INVULNERABLE:
      $CollisionShape2D.disabled = true
    DEAD:
      $CollisionShape2D.disabled = true
  state = new_state

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
  change_state(ALIVE)
  $GunTimer.wait_time = fire_rate

func _process(_delta):
  get_input()

func _integrate_forces(physics_state):
  set_applied_force(thrust.rotated(rotation))
  set_applied_torque(spin_power * rotation_dir)
  var xform = physics_state.get_transform()
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
