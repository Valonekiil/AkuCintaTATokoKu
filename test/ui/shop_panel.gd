class_name ShopItemPanel
extends Panel

const TRADE_STEP := 5.0

@onready var name_label: Label = $HBoxContainer/VBoxContainerLeft/ItemName
@onready var desc_label: Label = $HBoxContainer/VBoxContainerLeft/ItemDesc
@onready var category_label: Label = $HBoxContainer/VBoxContainerCenter/HBoxContainer/CategoryLabel
@onready var normal_price_label: Label = $HBoxContainer/VBoxContainerCenter/PriceContainer/PriceLabel
@onready var final_price_label: Label = $HBoxContainer/VBoxContainerCenter/HBoxContainer/FinalLabel
@onready var icon_rect: TextureRect = $HBoxContainer/TextureRect
@onready var buy_btn: Button = $HBoxContainer/VBoxContainerCenter/ButtonContainer/BuyBtn
@onready var sell_btn: Button = $HBoxContainer/VBoxContainerCenter/ButtonContainer/SellBtn

var _item: DynamicShopItem
var _multiplier: float = 1.0


func _ready() -> void:
	buy_btn.pressed.connect(_on_buy_pressed)
	sell_btn.pressed.connect(_on_sell_pressed)


func set_item_data(item: DynamicShopItem, multiplier: float) -> void:
	_item = item
	if item is DisplayItem:
		name_label.text = item.display_name
		desc_label.text = item.description
		icon_rect.texture = item.icon
	else:
		name_label.text = item.item_name
		desc_label.text = ""
	category_label.text = item.category.name if item.category else ""
	update_price(multiplier)


func update_price(multiplier: float) -> void:
	_multiplier = multiplier
	normal_price_label.text = "%.0f GOLD" % _item.current_price
	final_price_label.text = "%.0f GOLD" % (_item.current_price * _multiplier)


func _on_buy_pressed() -> void:
	_item.increase_price(TRADE_STEP)
	update_price(_multiplier)


func _on_sell_pressed() -> void:
	_item.reduce_price(TRADE_STEP)
	update_price(_multiplier)
