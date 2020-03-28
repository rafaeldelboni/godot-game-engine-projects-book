extends KinematicBody2D

export (int) var run_speed
export (int) var jump_speed
export (int) var gravity

enum {IDLE, RUN, JUMP_DOWN, JUMP_UP, HURT, DEAD}
var state: int
var anim: String
var new_anim: String
var velocity: Vector2 = Vector2()

func change_state(new_state: int) -> void:
  state = new_state
  match state:
    IDLE:
      new_anim = 'idle'
    RUN:
      new_anim = 'run'
    HURT:
      new_anim = 'hurt'
    JUMP_DOWN:
      new_anim = 'jump_down'
    JUMP_UP:
      new_anim = 'jump_up'
    DEAD:
      hide()

func get_input() -> void:
  if state == HURT:
    return
  var right = Input.is_action_pressed('right')
  var left = Input.is_action_pressed('left')
  var jump = Input.is_action_just_pressed('jump')

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

func ready(pos: Vector2) -> void:
  position = pos
  show()
  change_state(IDLE)

func _physics_process(delta: float) -> void:
  velocity.y += gravity * delta
  get_input()
  if new_anim != anim:
    anim = new_anim
    $AnimationPlayer.play(anim)
  velocity = move_and_slide(velocity, Vector2(0, -1))
