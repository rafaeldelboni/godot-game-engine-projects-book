extends Node

var num_levels: int = 2
var current_level: int = 1

var game_scene: String = 'res://Main.tscn'
var title_screen: String = 'res://ui/TitleScreen.tscn'

func restart() -> int:
  return get_tree().change_scene(title_screen)

func next_level() -> int:
  current_level += 1
  if current_level <= num_levels:
    return get_tree().reload_current_scene()
  return ERR_BUG
