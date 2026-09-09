class_name TestShopController
extends Node

@onready var shop: DynamicShop = $Junkfood_Store
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var gold_label: Label = $CanvasLayer/GoldLabel

var player_gold: int = 1000


func _ready() -> void:
	_update_gold_display()
	# Only the controller under Shop1 owns the keyboard demo input.
	shop_ui_owner = get_parent().name == "Shop1"

var shop_ui_owner: bool = false


func _input(event: InputEvent) -> void:
	if not shop_ui_owner:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			_change_junk_prices(25.0, true)
		elif event.keycode == KEY_E:
			_change_junk_prices(25.0, false)


## Drives the Observer pattern via the SignalManager singleton.
## notify_by_category broadcasts to every registered DynamicShop, which only
## applies the change to items whose category matches.
func _change_junk_prices(value: float, increase: bool) -> void:
	for item in shop.get_items():
		if item.category and item.category.name.to_upper() == "JUNK":
			SignalManager.notify_by_category(item.category, value, increase)
			break
	status_label.text = "🔔 JUNK %s price by %.0f gold" % ["↑" if increase else "↓", value]


func _notify_all_by_name(item_name: String, value: float, increase: bool) -> void:
	SignalManager.notify_by_name(item_name, value, increase)


func _update_gold_display() -> void:
	gold_label.text = "💰 Gold: %d" % player_gold
