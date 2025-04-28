extends Node

signal keyboard_key(key, pressed, echo)

func _on_input(event):
  if event is InputEventKey:
    keyboard_key.emit(event.keycode, event.pressed, event.echo)
