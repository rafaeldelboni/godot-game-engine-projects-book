extends Node2D

export (PackedScene) var Enemy

signal score_changed

var score: int
var Collectible: PackedScene = preload('res://items/Collectibles.tscn')

onready var pickups: TileMap = $Pickups

func set_camera_limits():
  var map_size: Rect2 = $World.get_used_rect()
  var cell_size: Vector2 = $World.cell_size
  $Player/Camera2D.limit_left = (map_size.position.x - 5) * cell_size.x
  $Player/Camera2D.limit_right = (map_size.end.x + 5) * cell_size.x

func spawn_pickups() -> void:
  for cell in pickups.get_used_cells():
    var id: int = pickups.get_cellv(cell)
    var type: String = pickups.tile_set.tile_get_name(id)
    if type in ['gem', 'cherry']:
      var c: Area2D = Collectible.instance()
      var pos: Vector2 = pickups.map_to_world(cell)
      c.init(type, pos + pickups.cell_size/2)
      add_child(c)
      c.connect('pickup', self, '_on_Collectible_pickup')

func _on_Collectible_pickup() -> void:
  score += 1
  emit_signal('score_changed', score)

func _on_Player_dead() -> void:
  print('dead')

func _ready() -> void:
  score = 0
  emit_signal('score_changed', score)
  pickups.hide()
  $Player.start($PlayerSpawn.position)
  for enemy in $Enemies.get_children():
    var s: KinematicBody2D = Enemy.instance()
    s.position = enemy.position
    add_child(s)
  set_camera_limits()
  spawn_pickups()
