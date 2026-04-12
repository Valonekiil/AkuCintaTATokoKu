class_name ShopItemPanel
extends Panel

## Signal untuk interaksi user
signal item_clicked(item_id: String)
signal item_hovered(item_id: String, is_hovered: bool)

## Node references (Unique Name dengan %)
@onready var item_name: Label = $HBoxContainer/VBoxContainerLeft/ItemName
@onready var item_desc: Label = $HBoxContainer/VBoxContainerLeft/ItemDesc
@onready var category_label: Label = $HBoxContainer/VBoxContainerRight/CategoryLabel
@onready var price_label: Label = $HBoxContainer/VBoxContainerRight/PriceLabel
@onready var elasticity_label: Label = $HBoxContainer/VBoxContainerRight/ElasticityLabel
@onready var icon_rect: TextureRect = $HBoxContainer/TextureRect

## Data internal
var _current_item_id: String = ""
var _baseline_price: float = 0.0
var _current_price: float = 0.0


func _ready() -> void:
	# Connect signal mouse enter/exit (Godot 4 compliant)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


## Set semua data item sekaligus
func set_item_data(item: DynamicShopItem) -> void:
	_current_item_id = item.item_id
	
	# Basic info
	item_name.text = item.display_name
	item_desc.text = item.description
	icon_rect.texture = item.icon
	
	# Category
	category_label.text = "[%s]" % item.category.to_upper()
	
	# Price calculation (Multiplicative Sampling - Bab 2.2.2)
	_baseline_price = item.base_worth * item.item_scale
	_current_price = _baseline_price  # Akan di-update oleh DynamicShop
	price_label.text = "%.0f GOLD" % _current_price
	
	# Elasticity display (Price Elasticity - Bab 2.2.2)
	_update_elasticity_display(item.price_elasticity)


## Update harga secara dinamis (dipanggil saat signal price_updated)
func update_price(new_price: float) -> void:
	if abs(new_price - _current_price) < 0.01:
		return  # Tidak ada perubahan signifikan
	
	var old_price = _current_price
	_current_price = new_price
	price_label.text = "%.0f GOLD" % _current_price
	
	# Visual feedback saat harga berubah (sesuai Bab 3.2.2.B - Event-Driven)
	if new_price > old_price:
		# Harga naik - flash merah
		price_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	else:
		# Harga turun - flash hijau
		price_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	
	# Animasi kembali ke warna emas setelah 0.5 detik
	await get_tree().create_timer(0.5).timeout
	price_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))


## Helper internal untuk elastisitas
func _update_elasticity_display(elasticity: float) -> void:
	elasticity_label.text = "Elasticity: %.2f" % elasticity
	
	if elasticity < 1.0:
		elasticity_label.text += " (Inelastis)"
		elasticity_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	elif elasticity > 1.0:
		elasticity_label.text += " (Elastis)"
		elasticity_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	else:
		elasticity_label.text += " (Netral)"
		elasticity_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))


## Input handling untuk click
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("item_clicked", _current_item_id)


## Signal handler untuk mouse enter/exit
func _on_mouse_entered() -> void:
	emit_signal("item_hovered", _current_item_id, true)
	modulate = Color(1.0, 1.0, 0.9, 1.0)


func _on_mouse_exited() -> void:
	emit_signal("item_hovered", _current_item_id, false)
	modulate = Color.WHITE


## Utility: Reset ke state default
func reset() -> void:
	_current_item_id = ""
	_baseline_price = 0.0
	_current_price = 0.0
	item_name.text = ""
	item_desc.text = ""
	price_label.text = ""
	elasticity_label.text = ""
	icon_rect.texture = null
