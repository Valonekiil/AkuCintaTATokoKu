class_name ShopItemPanel
extends Panel

## Signal untuk interaksi user
signal item_clicked(item_id: String)
signal item_hovered(item_id: String, is_hovered: bool)

## Node references (Unique Name dengan %)
@onready var item_name: Label = $HBoxContainer/VBoxContainerLeft/ItemName
@onready var item_desc: Label = $HBoxContainer/VBoxContainerLeft/ItemDesc
@onready var category_label: Label = $HBoxContainer/VBoxContainerCenter/HBoxContainer/CategoryLabel
@onready var price_label: Label = $HBoxContainer/VBoxContainerCenter/PriceContainer/PriceLabel
@onready var elasticity_label: Label = $HBoxContainer/VBoxContainerCenter/HBoxContainer/ElasticityLabel
@onready var icon_rect: TextureRect = $HBoxContainer/TextureRect
@onready var sparkline: PriceSparkline = $HBoxContainer/VBoxContainerCenter/PriceContainer/PriceSparkline
@onready var trend_icon: Label = $HBoxContainer/VBoxContainerCenter/PriceContainer/TrendIcon
@onready var tooltip: Panel = $Tooltip

# ⭐ FITUR BARU: Stock Display Nodes
@onready var stock_label: Label = $HBoxContainer/VBoxContainerCenter/StockContainer/StockLabel
@onready var stock_badge: Panel = $HBoxContainer/VBoxContainerCenter/StockContainer/StockBadge
@onready var out_of_stock_overlay: Panel = $OutOfStockOverlay
@onready var restock_timer_label: Label = $OutOfStockOverlay/RestockTimerLabel

## Data internal
var _current_item_id: String = ""
var _baseline_price: float = 0.0
var _current_price: float = 0.0
var _last_price: float = 0.0
var _purchase_count: int = 0
var _price_change_percent: float = 0.0
var _current_stock: int = 0
var _max_stock: int = 0
var _is_out_of_stock: bool = false


func _ready() -> void:
	# Connect signal mouse enter/exit (Godot 4 compliant)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Hide tooltip by default
	if tooltip:
		tooltip.visible = false


## Set semua data item sekaligus
func set_item_data(item: DynamicShopItem) -> void:
	_current_item_id = item.item_id
	print("set item: ", item.item_id)
	# Basic info
	item_name.text = item.display_name
	item_desc.text = item.description
	icon_rect.texture = item.icon
	
	# Category
	category_label.text = "[%s]" % item.category.to_upper()
	
	# Price calculation (Multiplicative Sampling - Bab 2.2.2)
	_baseline_price = item.base_worth * item.item_scale
	_current_price = _baseline_price
	_last_price = _current_price
	price_label.text = "%.0f GOLD" % _current_price
	
	# Initialize sparkline dengan baseline price
	if sparkline:
		sparkline.reset()
		for i in range(5):  # Pre-fill dengan baseline untuk visual awal
			sparkline.add_price(_baseline_price)
	
	# Elasticity display (Price Elasticity - Bab 2.2.2)
	_update_elasticity_display(item.price_elasticity)
	
	# Reset trend icon
	if trend_icon:
		trend_icon.text = "➡️"
	
	# ⭐ FITUR BARU: Initialize stock display
	_current_stock = item.current_stock
	_max_stock = item.max_stock
	_is_out_of_stock = item.current_stock <= 0
	update_stock(_current_stock)


## Update harga secara dinamis (dipanggil saat signal price_updated)
func update_price(new_price: float) -> void:
	if abs(new_price - _current_price) < 0.01:
		return  # Tidak ada perubahan signifikan
	
	_last_price = _current_price
	_current_price = new_price
	
	# Hitung persentase perubahan
	if _last_price > 0:
		_price_change_percent = ((new_price - _last_price) / _last_price) * 100
	
	# Update label harga dengan animasi tween (Bab 3.2.3 - Smooth UI)
	_animate_price_change(_last_price, new_price)
	
	# Update sparkline
	if sparkline:
		sparkline.add_price(new_price)
	
	# Update trend icon
	_update_trend_icon()
	

## ⭐ FITUR BARU: Update stock display (dipanggil saat signal stock_updated)
func update_stock(new_stock: int) -> void:
	_current_stock = new_stock
	_is_out_of_stock = new_stock <= 0
	
	_update_stock_display(new_stock, _max_stock)
	set_out_of_stock(_is_out_of_stock)


## ⭐ Helper internal untuk update stock badge dan warna
func _update_stock_display(stock: int, max_stock: int) -> void:
	if not stock_label or not stock_badge:
		return
	
	# Update text: "[stock/max_stock]"
	stock_label.text = "[%d/%d]" % [stock, max_stock]
	
	# Update warna badge berdasarkan stock percentage
	var stock_percentage = float(stock) / float(max_stock) if max_stock > 0 else 0.0
	
	if stock <= 0:
		# Out of stock: abu-abu
		stock_badge.self_modulate = Color(0.5, 0.5, 0.5, 1.0)
	elif stock_percentage <= 0.2:
		# Low stock (<20%): merah
		stock_badge.self_modulate = Color(1.0, 0.3, 0.3, 1.0)
	elif stock_percentage <= 0.5:
		# Medium stock (20-50%): kuning
		stock_badge.self_modulate = Color(1.0, 0.8, 0.2, 1.0)
	else:
		# High stock (>50%): hijau
		stock_badge.self_modulate = Color(0.3, 1.0, 0.4, 1.0)


## ⭐ Set overlay "Out of Stock" dan disable interaction
func set_out_of_stock(is_out: bool) -> void:
	if out_of_stock_overlay:
		out_of_stock_overlay.visible = is_out
	
	# Disable mouse interaction jika out of stock
	if is_out:
		mouse_filter = Control.MOUSE_FILTER_STOP
		modulate = Color(0.6, 0.6, 0.6, 1.0)  # Greyed out
	else:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate = Color.WHITE
	
	# Update tooltip data
	_update_tooltip_data()


## Animasi harga dengan tween (smooth transition)
func _animate_price_change(from_price: float, to_price: float) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Animasi angka harga (0.3 detik)
	tween.tween_method(
		_update_price_label,
		from_price,
		to_price,
		0.3
	)
	
	# Flash warna berdasarkan arah perubahan
	var flash_color = Color(1.0, 0.4, 0.4, 1.0) if to_price > from_price else Color(0.4, 1.0, 0.4, 1.0)
	price_label.add_theme_color_override("font_color", flash_color)
	
	# Kembali ke warna emas setelah 0.5 detik
	tween.tween_callback(func():
		price_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	).set_delay(0.5)


## Helper untuk tween (update label text)
func _update_price_label(value: float) -> void:
	price_label.text = "%.0f GOLD" % value


## Update trend icon berdasarkan arah harga
func _update_trend_icon() -> void:
	if not trend_icon:
		return
	
	if _price_change_percent > 1.0:
		trend_icon.text = "📈"  # Naik
	elif _price_change_percent < -1.0:
		trend_icon.text = "📉"  # Turun
	else:
		trend_icon.text = "➡️"  # Stabil


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


## Update tooltip dengan data lengkap
func _update_tooltip_data() -> void:
	if not tooltip:
		return
	
	var change_text = ""
	if _price_change_percent > 0:
		change_text = "+%.1f%%" % _price_change_percent
	elif _price_change_percent < 0:
		change_text = "%.1f%%" % _price_change_percent
	else:
		change_text = "0%"
	
	tooltip.get_node("VBoxContainer/InitialPrice").text = "Initial: %.2f GOLD" % _baseline_price
	tooltip.get_node("VBoxContainer/CurrentPrice").text = "Current: %.2f GOLD" % _current_price
	tooltip.get_node("VBoxContainer/Change").text = "Change: %s" % change_text
	tooltip.get_node("VBoxContainer/Purchases").text = "Purchases: %d times" % _purchase_count
	
	# ⭐ FITUR BARU: Tambah info stok di tooltip
	if tooltip.has_node("VBoxContainer/StockInfo"):
		tooltip.get_node("VBoxContainer/StockInfo").text = "Stock: %d/%d" % [_current_stock, _max_stock]


## Increment purchase count (dipanggil saat beli)
func add_purchase() -> void:
	_purchase_count += 1
	_update_tooltip_data()


## Input handling untuk click
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("item_clicked", _current_item_id)


## Signal handler untuk mouse enter/exit (Tooltip follow mouse)
func _on_mouse_entered() -> void:
	emit_signal("item_hovered", _current_item_id, true)
	modulate = Color(1.0, 1.0, 0.9, 1.0)
	
	# Show tooltip
	if tooltip:
		tooltip.visible = true
		tooltip.global_position = get_global_mouse_position() + Vector2(20, 20)


func _on_mouse_exited() -> void:
	emit_signal("item_hovered", _current_item_id, false)
	modulate = Color.WHITE
	
	# Hide tooltip
	if tooltip:
		tooltip.visible = false


## Update tooltip position saat mouse move (follow cursor)
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and tooltip and tooltip.visible:
		tooltip.global_position = get_global_mouse_position() + Vector2(20, 20)


## Utility: Reset ke state default
func reset() -> void:
	_current_item_id = ""
	_baseline_price = 0.0
	_current_price = 0.0
	_last_price = 0.0
	_purchase_count = 0
	_price_change_percent = 0.0
	item_name.text = ""
	item_desc.text = ""
	price_label.text = ""
	elasticity_label.text = ""
	icon_rect.texture = null
	if sparkline:
		sparkline.reset()
	if tooltip:
		tooltip.visible = false
