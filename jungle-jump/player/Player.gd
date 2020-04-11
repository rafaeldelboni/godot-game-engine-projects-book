extends KinematicBody2D

signal life_changed
signal dead

export (int) var run_speed
export (int) var jump_speed
export (int) var gravity

enum {IDLE, RUN, JUMP_DOWN, JUMP_UP, HURT, DEAD}
var state: int
var anim: String
var new_anim: String
var velocity: Vector2 = Vector2()
var life: int

func change_state(new_state: int) -> void:
  state = new_state
  match state:
    IDLE:
      new_anim = 'idle'
    RUN:
      new_anim = 'run'
    JUMP_DOWN:
      new_anim = 'jump_down'
    JUMP_UP:
      new_anim = 'jump_up'
    HURT:
      new_anim = 'hurt'
      velocity.y = -200
      velocity.x = -100 * sign(velocity.x)
      life -= 1
      emit_signal('life_changed', life)
      yield(get_tree().create_timer(0.5), 'timeout')
      change_state(IDLE)
      if life <= 0:
        change_state(DEAD)
    DEAD:
      emit_signal('dead')
      hide()

func get_input() -> void:
  if state == HURT:
    return
  var right: bool = Input.is_action_pressed('right')
  var left: bool = Input.is_action_pressed('left')
  var jump: bool = Input.is_action_just_pressed('jump')

  velocity.x = 0
  if right:
    velocity.x += run_speed
    $Sprite.flip_h = false
  if left:
    velocity.x -= run_speed
    $Sprite.flip_h = true
  if jump and is_on_floor():
    change_state(JUMP_UP)
    velocity.y = jump_speed
  if state == IDLE and velocity.x != 0:
    change_state(RUN)
  if state == RUN and velocity.x == 0:
    change_state(IDLE)
  if state in [IDLE, RUN] and !is_on_floor():
    change_state(JUMP_DOWN)
  if state in [JUMP_DOWN, JUMP_UP] and is_on_floor():
    change_state(IDLE)
  if state in [JUMP_DOWN, JUMP_UP] and velocity.y < 0:
    change_state(JUMP_UP)
  if state in [JUMP_DOWN, JUMP_UP] and velocity.y > 0:
    change_state(JUMP_DOWN)

func hurt() -> void:
  if state != HURT:
    change_state(HURT)

func start(pos: Vector2) -> void:
  position = pos
  show()
  life = 3
  emit_signal('life_changed', life)
  change_state(IDLE)

func _ready() -> void:
  change_state(IDLE)

func _physics_process(delta: float) -> void:
  velocity.y += gravity * delta
  get_input()
  if new_anim != anim:
    anim = new_anim
    $AnimationPlayer.play(anim)
  # velocity = move_and_slide(velocity, Vector2(0, -1))
  velocity = move_and_slide_with_snap(velocity, Vector2.ZERO, Vector2(0, -1), true, 4, deg2rad(45), true)
  if state == HURT:
    return
  for idx in range(get_slide_count()):
    var collision: KinematicCollision2D = get_slide_collision(idx)
    if collision.collider.name == 'Danger':
      hurt()
    if collision.collider.is_in_group('enemies'):
      var player_feet: float = (position + $CollisionShape2D.shape.extents).y
      if player_feet < collision.collider.position.y:
        collision.collider.take_damage()
        velocity.y = -200
      else:
        hurt()
