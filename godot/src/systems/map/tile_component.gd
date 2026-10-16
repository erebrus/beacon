class_name TileComponent extends Node2D

signal interacted


@export var target: Node
@export var can_interact: bool
@export var exclusive_cell_use:= true

var cell: Vector2i



func interact() -> void:
	interacted.emit()
