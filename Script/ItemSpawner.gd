extends Area2D

@export var Spawned_Items:Array[DynamicShopItem]
@export_range(1.0, 5.0, 1.0) var Max_Spawned:int
var spawned_count:int = 0
@export var Delay:float
@onready var timer: Timer = $Timer
@onready var colshape: CollisionShape2D = $CollisionShape2D
