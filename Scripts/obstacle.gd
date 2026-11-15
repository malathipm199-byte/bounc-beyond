extends Node2D

@export var move_offset := Vector2(140, 0)
@export var move_speed := 2.0
@export var is_moving_block := false

var start_pos := Vector2.ZERO
var t := 0.0

func _ready() -> void:
	start_pos = position

func _physics_process(delta: float) -> void:
	if is_moving_block:
		t += delta * move_speed
		var factor := (sin(t) + 1.0) * 0.5
		position = start_pos.lerp(start_pos + move_offset, factor)
