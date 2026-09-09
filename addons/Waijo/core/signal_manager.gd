extends Node
## Subject/Singleton in the Observer Pattern.

## filter_data: { "type": "name"|"category"|"sub_category", "key": String|ShopCategory, "value": float, "increase": bool }
signal price_change_requested(filter_data: Dictionary)


func notify_by_name(item_name: String, value: float, increase: bool = true) -> void:
	price_change_requested.emit({
		"type": "name",
		"key": item_name,
		"value": value,
		"increase": increase,
	})


func notify_by_category(category: ShopCategory, value: float, increase: bool = true) -> void:
	price_change_requested.emit({
		"type": "category",
		"key": category,
		"value": value,
		"increase": increase,
	})


func notify_by_sub_category(sub_category: ShopCategory, value: float, increase: bool = true) -> void:
	price_change_requested.emit({
		"type": "sub_category",
		"key": sub_category,
		"value": value,
		"increase": increase,
	})


func register_observer(callable: Callable) -> void:
	if not price_change_requested.is_connected(callable):
		price_change_requested.connect(callable)


func unregister_observer(callable: Callable) -> void:
	if price_change_requested.is_connected(callable):
		price_change_requested.disconnect(callable)
