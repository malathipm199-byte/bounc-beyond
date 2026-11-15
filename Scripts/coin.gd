extends Area2D

signal collected(coin_node: Area2D)

var base_y := 0.0
var time_passed := 0.0
var is_collected := false

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	time_passed += delta * 4.0
	position.y = base_y + sin(time_passed) * 5.0

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.name == "Player" or body.is_in_group("player"):
		is_collected = true
		collected.emit(self)
		visible = false
		set_deferred("monitoring", false)
