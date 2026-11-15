extends CharacterBody2D

const SPEED := 320.0
const JUMP_FORCE := -480.0
const GRAVITY := 1250.0

var can_control := false

func _physics_process(delta: float) -> void:
	if not can_control:
		velocity = Vector2.ZERO
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Horizontal movement (supports custom actions + fallback ui keys)
	var direction := Input.get_axis("move_left", "move_right")
	if direction == 0.0:
		direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * SPEED

	# Jump when freshly pressed on floor
	var jump_pressed := Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_up")
	if jump_pressed and is_on_floor():
		velocity.y = JUMP_FORCE

	move_and_slide()

func bounce(force: float = -760.0) -> void:
	velocity.y = force
