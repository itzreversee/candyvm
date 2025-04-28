extends Control

signal input(event)

func _input(event):
  input.emit(event)
