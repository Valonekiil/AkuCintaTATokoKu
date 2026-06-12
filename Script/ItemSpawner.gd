extends Area2D

@export var Spawned_Items:Array[DynamicShopItem]
@export_range(1.0, 5.0, 1.0) var Max_Spawned:int
var spawned_count:int = 0
@export var Delay:float
@onready var timer: Timer = $Timer
@onready var colshape: CollisionShape2D = $CollisionShape2D
@onready var indicator: Label = $Label
@export var shop_ui:CanvasLayer

func _ready() -> void:
	indicator.visible = false
	shop_ui.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_TAB) and player_near:
		shop_ui.visible = !shop_ui.visible
		print("i[t]")

var player_near:bool

func _on_body_entered(body: Node2D) -> void:
	player_near = true
	print("ada")

func _on_body_exited(body: Node2D) -> void:
	player_near = false
	if shop_ui.visible:
		shop_ui.visible = false
	print("g ada")
