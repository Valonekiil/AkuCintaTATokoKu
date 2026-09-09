@tool
class_name DynamicShop
extends Node
## Observer in the Observer Pattern.

@export var shop_items: Array[DynamicShopItem] = []
@export var shop_ui: ShopUI
@export var price_multiplier: float = 1.0

var _items: Array[DynamicShopItem] = []


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_items = []
	for item in shop_items:
		_items.append(item.duplicate())
	SignalManager.register_observer(_on_price_change_requested)
	if shop_ui:
		shop_ui.build_from_items(_items)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	SignalManager.unregister_observer(_on_price_change_requested)


func get_items() -> Array[DynamicShopItem]:
	return _items


func _on_price_change_requested(filter_data: Dictionary) -> void:
	for item in _items:
		if not _item_matches(item, filter_data):
			continue
		if filter_data["increase"]:
			item.increase_price(filter_data["value"])
		else:
			item.reduce_price(filter_data["value"])
		if shop_ui:
			shop_ui.update_item_display(item)


func _item_matches(item: DynamicShopItem, filter_data: Dictionary) -> bool:
	match filter_data["type"]:
		"name":
			return item.item_name == filter_data["key"]
		"category":
			return item.category == filter_data["key"]
		"sub_category":
			return item.sub_category == filter_data["key"]
		_:
			return false
