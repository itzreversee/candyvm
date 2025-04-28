extends Node2D

signal vm_run

func _ready():
  vm_run.emit()
