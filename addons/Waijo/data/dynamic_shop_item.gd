@tool
class_name DynamicShopItem
extends Resource
## Data class for a single shop item.

## Emitted when current_price changes.
signal price_changed(item: DynamicShopItem)

@export var item_name: String = ""
@export var category: ShopCategory
@export var sub_category: ShopCategory
@export var base_price: float = 0.0
@export var current_price: float = 0.0


func increase_price(value: float) -> void:
	current_price += value
	price_changed.emit(self)


func reduce_price(value: float) -> void:
	current_price = max(current_price - value, 0.0)
	price_changed.emit(self)


func reset_price() -> void:
	current_price = base_price
	price_changed.emit(self)
