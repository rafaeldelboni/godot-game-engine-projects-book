extends Node2D

export (PackedScene) var Enemy

signal score_changed

var score: int
var Collectible: PackedScene = preload('res://items/Collectibles.tscn')

onready var pickups: TileMap = $Pickups

func set_camera_limits():
  var map_size = $World.get_used_rect()
  var cell_size = $World.cell_size
  $Player/Camera2D.limit_left = (map_size.position.x - 5) * cell_size.x
  $Player/Camera2D.limit_right = (map_size.end.x + 5) * cell_size.x

func spawn_pickups() -> void:
  for cell in pickups.get_used_cells():
    var id = pickups.get_cellv(cell)
    var type = pickups.tile_set.tile_get_name(id)
    if type in ['gem', 'cherry']:
      var c = Collectible.instance()
      var pos = pickups.map_to_world(cell)
      c.init(type, pos + pickups.cell_size/2)
      add_child(c)
      c.connect('pickup', self, '_on_Collectible_pickup')

func _on_Collectible_pickup() -> void:
  score += 1
  emit_signal('score_changed', score)

func _on_Player_dead() -> void:
  pass

func _ready() -> void:
  score = 0
  emit_signal('score_changed', score)
  pickups.hide()
  $Player.start($PlayerSpawn.position)
  for enemy in $Enemies.get_children():
    var s = Enemy.instance()
    s.position = enemy.position
    add_child(s)
  set_camera_limits()
  spawn_pickups()
