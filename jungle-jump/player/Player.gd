extends KinematicBody2D

signal life_changed
signal dead

export (int) var run_speed
export (int) var climb_speed
export (int) var jump_speed
export (int) var gravity

enum {IDLE, RUN, JUMP_DOWN, JUMP_UP, DOUBLE_JUMP, HURT, DEAD, CROUCH, CLIMB}
var state: int
var anim: String
var new_anim: String
var velocity: Vector2 = Vector2()
var life: int

var max_jumps: int = 2
var jump_count: int = 0

var is_on_ladder: bool = false

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
      jump_count = 1
    DOUBLE_JUMP:
      new_anim = 'jump_up'
      jump_count += 1
    HURT:
      new_anim = 'hurt'
      $HurtSound.play()
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
    CROUCH:
      new_anim = 'crouch'
    CLIMB:
      new_anim = 'climb'

func get_input() -> void:
  if state == HURT:
    return
  var right: bool = Input.is_action_pressed('right')
  var left: bool = Input.is_action_pressed('left')
  var down: bool = Input.is_action_pressed('crouch')
  var climb: bool = Input.is_action_pressed('climb')
  var jump: bool = Input.is_action_just_pressed('jump')

  velocity.x = 0
  if right:
    velocity.x += run_speed
    $Sprite.flip_h = false
  if left:
    velocity.x -= run_speed
    $Sprite.flip_h = true
  if down and is_on_floor():
    change_state(CROUCH)
  if !down and state == CROUCH:
    change_state(IDLE)
  if jump and state in [JUMP_DOWN, JUMP_UP] and jump_count < max_jumps:
    change_state(DOUBLE_JUMP)
    velocity.y = jump_speed / 1.5
  if jump and is_on_floor():
    change_state(JUMP_UP)
    $JumpSound.play()
    velocity.y = jump_speed
  if climb and state != CLIMB and is_on_ladder:
    change_state(CLIMB)
  if state == CLIMB:
    if climb:
      velocity.y = -climb_speed
    elif down:
      velocity.y = climb_speed
    else:
      velocity.y = 0
  if state == CLIMB and not is_on_ladder:
    change_state(IDLE)
  if state in [IDLE, CROUCH] and velocity.x != 0:
    change_state(RUN)
  if state == RUN and velocity.x == 0:
    change_state(IDLE)
  if state in [IDLE, RUN] and !is_on_floor():
    change_state(JUMP_DOWN)
  if state in [JUMP_DOWN, JUMP_UP] and is_on_floor():
    change_state(IDLE)
    $Dust.emitting = true
  if state in [JUMP_DOWN, JUMP_UP] and velocity.y < 0:
    change_state(JUMP_UP)
  if state in [JUMP_DOWN, JUMP_UP, DOUBLE_JUMP] and velocity.y > 0:
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
  if state != CLIMB:
    velocity.y += gravity * delta
  get_input()
  if new_anim != anim:
    anim = new_anim
    $AnimationPlayer.play(anim)
  if position.y > 1000:
    change_state(DEAD)
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
