extends Node2D

export (PackedScene) var Rock
export (PackedScene) var Enemy

var screensize = Vector2()
var level = 0
var score = 0
var playing = false

func new_level():
  $LevelupSound.play()
  level += 1
  $HUD.show_message("Wave %s" % level)
  for _i in range(level):
    spawn_rock(3)
  $EnemyTimer.wait_time = rand_range(5, 10)
  $EnemyTimer.start()

func new_game():
  $Music.play()
  for rock in $Rocks.get_children():
    rock.queue_free()
  for enemy in $Enemies.get_children():
    enemy.queue_free()
  level = 0
  score = 0
  $HUD.update_score(score)
  $Player.start()
  $HUD.show_message("Get Ready!")
  yield($HUD/MessageTimer, "timeout")
  playing = true
  new_level()

func game_over():
  $ExplodeSound.play()
  $Music.stop()
  playing = false
  $HUD.game_over()

func spawn_rock(size, pos=null, vel=null):
  if !pos:
    $RockPath/RockSpawn.set_offset(randi())
    pos = $RockPath/RockSpawn.position
  if !vel:
    vel = Vector2(1, 0).rotated(rand_range(0, 2*PI)) * rand_range(100, 150)
  var r = Rock.instance()
  r.screensize = screensize
  r.start(pos, vel, size)
  r.connect('exploded', self, '_on_Rock_exploded')
  $Rocks.add_child(r)

func _process(_delta):
  if playing and $Rocks.get_child_count() == 0:
    new_level()

func _ready():
  randomize()
  screensize = get_viewport().get_visible_rect().size
  $Player.screensize = screensize

func _on_Rock_exploded(size, radius, pos, vel):
  $ExplodeSound.play()
  score += size * 10
  $HUD.update_score(score)
  if size <= 1:
    return
  for offset in [-1, 1]:
    var dir = (pos - $Player.position).normalized().tangent() * offset
    var newpos = pos + dir * radius
    var newvel = dir * vel.length() * 1.1
    spawn_rock(size - 1, newpos, newvel)

func _on_Enemy_exploded():
  $ExplodeSound.play()
  score += level * 10
  $HUD.update_score(score)

func _on_Player_shoot(bullet, pos, dir):
  var b = bullet.instance()
  b.start(pos, dir)
  add_child(b)

func _input(event):
  if event.is_action_pressed('pause'):
    if not playing:
      return
    get_tree().paused = not get_tree().paused
    if get_tree().paused:
      $HUD/MessageLabel.text = "Paused"
      $HUD/MessageLabel.show()
    else:
      $HUD/MessageLabel.text = ""
      $HUD/MessageLabel.hide()

func _on_EnemyTimer_timeout():
  var e = Enemy.instance()
  e.target = $Player
  e.connect('shoot', self, '_on_Player_shoot')
  e.connect('exploded', self, '_on_Enemy_exploded')
  $Enemies.add_child(e)
  $EnemyTimer.wait_time = rand_range(20, 40)
  $EnemyTimer.start()
