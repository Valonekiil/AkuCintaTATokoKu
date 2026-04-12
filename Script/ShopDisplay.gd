extends Panel
class_name ShopDisplay

@onready var items_container: VBoxContainer = $VBoxContainer/ItemsContainer
@export var shop: DynamicShop

@export var item_template: PackedScene = preload("res://DynamicItemPanel.tscn")

func _ready() -> void:
	if shop == null:
		push_error("⚠️ Tidak menemukan node DynamicShop! Pastikan ada node 'DynamicShop' di scene ini.")
		return
	
	_populate_items()

func _populate_items() -> void:
	# Bersihkan container
	for child in items_container.get_children():
		child.queue_free()
	
	var items = shop.get_all_registered_items()
	
	if items.is_empty():
		var empty = Label.new()
		empty.text = "📭 Toko kosong"
		empty.add_theme_font_size_override("font_size", 16)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		items_container.add_child(empty)
		return
	
	# Buat UI untuk setiap item
	for item in items:
		_create_item_ui(item)

func _create_item_ui(item: DynamicShopItem) -> void:
	var instance: ShopItemPanel = item_template.instantiate()
	items_container.add_child(instance)
	# ✨ Hanya 2 baris!
	instance.set_item_data(item)
	instance.item_clicked.connect(_on_item_clicked)
	

func _on_item_clicked(item_id: String) -> void:
	print("Player clicked: ", item_id)
	# Handle purchase logic here
	shop.purchase_item(item_id,1)
	_populate_items()

func refresh_display() -> void:
	_populate_items()
