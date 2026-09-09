extends Node

@export var shop: DynamicShop


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	print("notify_by_name: Minor Healing Potion -10")
	SignalManager.notify_by_name("Minor Healing Potion", 10.0, false)
	_print_prices()

	await get_tree().create_timer(2.0).timeout
	var sword := _find_item("Iron Sword")
	print("notify_by_category: Equipment +20")
	SignalManager.notify_by_category(sword.category, 20.0, true)
	_print_prices()

	await get_tree().create_timer(2.0).timeout
	var mana := _find_item("Mana Potion")
	print("notify_by_sub_category: Potion +5")
	SignalManager.notify_by_sub_category(mana.sub_category, 5.0, true)
	_print_prices()


func _find_item(item_name: String) -> DynamicShopItem:
	for item in shop.get_items():
		if item.item_name == item_name:
			return item
	return null


func _print_prices() -> void:
	for item in shop.get_items():
		print("%s: %.0f" % [item.item_name, item.current_price])
