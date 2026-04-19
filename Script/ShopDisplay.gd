class_name ShopDisplay
extends Control

@onready var items_container: VBoxContainer = $VBoxContainer/ItemsContainer
@export var shop: DynamicShop 
@onready var title_label: Label = $VBoxContainer/TitleLabel

@export var item_template: PackedScene = preload("res://DynamicItemPanel.tscn")

## Cache referensi ke panel item untuk update cepat
var _item_panels: Dictionary = {}  # {item_id: ShopItemPanel}


func _ready() -> void:
	if shop == null:
		push_error("⚠️ Tidak menemukan node DynamicShop!")
		return
	
	# Connect ke signal DynamicShop (Event-Driven - Bab 3.2.2.B)
	shop.item_purchased.connect(_on_item_purchased)
	shop.item_sold.connect(_on_item_sold)
	shop.price_updated.connect(_on_price_updated)
	shop.shop_initialized.connect(_on_shop_initialized)
	
	_populate_items()
	print("✓ ShopDisplay connected to DynamicShop signals")


func _populate_items() -> void:
	# Bersihkan container
	for child in items_container.get_children():
		child.queue_free()
	_item_panels.clear()
	
	var items = shop.get_all_registered_items()
	
	if items.is_empty():
		var empty = Label.new()
		empty.text = "📭 Toko kosong"
		empty.add_theme_font_size_override("font_size", 16)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(empty)
		return
	
	for item in items:
		_create_item_ui(item)
	
	title_label.text = "🏪 %s" % shop.shop_name


func _create_item_ui(item: DynamicShopItem) -> void:
	var instance: ShopItemPanel = item_template.instantiate()
	items_container.add_child(instance)
	instance.set_item_data(item)
	instance.item_clicked.connect(_on_item_clicked)
	_item_panels[item.item_id] = instance
	


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_item_purchased(item_id: String, quantity: int, final_price: float) -> void:
	print("🛒 [UI] Player purchased %d x %s @ %.2f" % [quantity, item_id, final_price])
	
	# Update purchase count di panel
	if _item_panels.has(item_id):
		var panel: ShopItemPanel = _item_panels[item_id]
		for i in range(quantity):
			panel.add_purchase()


func _on_item_sold(item_id: String, quantity: int, final_price: float) -> void:
	print("💰 [UI] Player sold %d x %s @ %.2f" % [quantity, item_id, final_price])


func _on_price_updated(item_id: String, new_price: float) -> void:
	if _item_panels.has(item_id):
		var panel: ShopItemPanel = _item_panels[item_id]
		panel.update_price(new_price)
		print("📊 [UI] Price updated: %s → %.2f GOLD" % [item_id, new_price])


func _on_shop_initialized(shop_name: String, item_count: int) -> void:
	print("🏪 [UI] Shop '%s' initialized with %d items" % [shop_name, item_count])


func _on_item_clicked(item_id: String) -> void:
	#print("🖱️ [UI] Item clicked: %s" % item_id)
	if shop:
		shop.purchase_item(item_id, 1)


func refresh_display() -> void:
	_populate_items()
