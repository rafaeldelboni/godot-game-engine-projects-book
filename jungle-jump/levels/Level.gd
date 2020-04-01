extends Node2D

onready var pickups = $Pickups

func _ready() -> void:
  pickups.hide()
  $Player.start($PlayerSpawn.position)
