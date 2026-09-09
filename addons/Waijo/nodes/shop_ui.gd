@tool
class_name ShopUI
extends Control
## View Layer (SRP: Presentation Class).

@export var item_container: VBoxContainer

var _item_labels: Dictionary = {}  # DynamicShopItem -> Label


func build_from_items(items: Array[DynamicShopItem]) -> void:
	_clear_container()
	_item_labels.clear()
	if not item_container:
		push_warning("ShopUI.item_container is not assigned.")
		return
	for item in items:
		var label := Label.new()
		_item_labels[item] = label
		item_container.add_child(label)
		update_item_display(item)


func update_item_display(item: DynamicShopItem) -> void:
	if not _item_labels.has(item):
		return
	var label: Label = _item_labels[item]
	label.text = "%s — %.0f gold" % [item.item_name, item.current_price]


func refresh_shop_interface() -> void:
	for item in _item_labels.keys():
		update_item_display(item)


func _clear_container() -> void:
	if not item_container:
		return
	for child in item_container.get_children():
		child.queue_free()
