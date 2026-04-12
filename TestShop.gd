class_name TestShopController
extends Node

@onready var shop: DynamicShop = $Junkfood_Store
@onready var shop_display: ShopDisplay = $CanvasLayer/PanelRoot

## UI References (untuk test manual)
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var gold_label: Label = $CanvasLayer/GoldLabel

var player_gold: int = 1000


func _ready() -> void:
	# Connect signals untuk logging
	shop.item_purchased.connect(_on_purchase_completed)
	shop.item_sold.connect(_on_sell_completed)
	
	_update_gold_display()
	
	print("\n========================================")
	print("🎮 TEST SHOP SCENE READY")
	print("========================================")
	print("Player Gold: %d" % player_gold)
	print("Instructions:")
	print("  - Click item di UI untuk beli (auto 1x)")
	print("  - Tekan 'S' untuk sell item test")
	print("  - Tekan 'R' untuk reset history")
	print("========================================\n")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S:
			_test_sell()
		elif event.keycode == KEY_R:
			_test_reset()

func _on_purchase_completed(item_id: String, quantity: int, final_price: float) -> void:
	var total = final_price * quantity
	if player_gold >= total:
		player_gold -= int(total)
		_update_gold_display()
		status_label.text = "🛒 Bought %d x %s (%.0f gold)" % [quantity, item_id, total]
	else:
		status_label.text = "❌ Not enough gold!"


func _on_sell_completed(item_id: String, quantity: int, final_price: float) -> void:
	var total = final_price * quantity
	player_gold += int(total)
	_update_gold_display()
	status_label.text = "💰 Sold %d x %s (%.0f gold)" % [quantity, item_id, total]


func _test_sell() -> void:
	# Test sell function (untuk demo harga turun)
	var items = shop.get_all_registered_items()
	if items.size() > 0:
		var item = items[0]
		shop.sell_item(item.item_id, 1)


func _test_reset() -> void:
	shop.reset_history()
	status_label.text = "🔄 History reset!"
	print("✓ Reset all purchase/sell history")


func _update_gold_display() -> void:
	gold_label.text = "💰 Gold: %d" % player_gold
