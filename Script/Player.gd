extends CharacterBody2D
class_name Player

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var cur_shop:DynamicShop
@onready var notifier: Label = $Notifier

func _ready() -> void:
	notifier.visible = false

func _physics_process(delta: float) -> void:
	var direction_X := Input.get_axis("ui_left", "ui_right")
	if direction_X:
		velocity.x = direction_X * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	var direction_y := Input.get_axis("ui_up", "ui_down")
	if direction_y:
		velocity.y = direction_y * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

func show_notif()-> void:
	notifier.visible = true

func hide_notif()-> void:
	notifier.visible = false
