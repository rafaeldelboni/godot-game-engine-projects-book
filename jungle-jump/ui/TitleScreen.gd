extends Control

func _input(event) -> void:
  if event.is_action_pressed('ui_select'):
    var changed_state_status: int = get_tree().change_scene(GameState.game_scene)
    if changed_state_status != OK:
      print("error: ", changed_state_status)

