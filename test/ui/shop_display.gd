class_name ShopDisplay
extends ShopUI

@export var shop: DynamicShop
@export var item_panel_scene: PackedScene = preload("res://test/ui/shop_panel.tscn")

var _item_panels: Dictionary = {}  # DynamicShopItem -> ShopItemPanel


func build_from_items(items: Array[DynamicShopItem]) -> void:
	for child in item_container.get_children():
		child.queue_free()
	_item_panels.clear()
	for item in items:
		var panel: ShopItemPanel = item_panel_scene.instantiate()
		item_container.add_child(panel)
		panel.set_item_data(item, shop.price_multiplier)
		_item_panels[item] = panel


func update_item_display(item: DynamicShopItem) -> void:
	if not _item_panels.has(item):
		return
	_item_panels[item].update_price(shop.price_multiplier)


func refresh_shop_interface() -> void:
	for item in _item_panels.keys():
		update_item_display(item)
