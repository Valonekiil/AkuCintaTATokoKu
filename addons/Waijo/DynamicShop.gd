@tool
class_name DynamicShop
extends Node

# ============================================================================
# SIGNAL (Event-Driven Architecture - Bab 3.2.2.B)
# ============================================================================
signal item_purchased(item_id: String, quantity: int, final_price: float)
signal item_sold(item_id: String, quantity: int, final_price: float)
signal price_updated(item_id: String, new_price: float)
signal shop_initialized(shop_name: String, item_count: int)
signal item_scale_updated(item_id: String, new_scale: float)  # ✅ NEW

# ============================================================================
# KONFIGURASI (Inspector)
# ============================================================================
@export var shop_name: String = "General Store"
@export var shop_items: Array[DynamicShopItem] = []

# ============================================================================
# DATA RUNTIME
# ============================================================================
var _registered_items: Dictionary = {}  # {item_id: DynamicShopItem}
var _purchase_history: Dictionary = {}  # {item_id: purchase_count}
var _sell_history: Dictionary = {}  # {item_id: sell_count}
var _current_prices: Dictionary = {}  # {item_id: current_price}

# Reference to PricingEngine (Singleton - Auto-Registered via plugin.gd)
var pricing_engine: PricingEngine = PriceManager


# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	# Initialize original scales for all items
	for item in shop_items:
		if item:
			item.set_original_scale()
	
	# Connect to PricingEngine signals (Event-Driven - Bab 3.2.2.B)
	pricing_engine.price_changed.connect(_on_price_changed)
	pricing_engine.category_scale_changed.connect(_on_category_scale_changed)
	pricing_engine.global_event_triggered.connect(_on_global_event_triggered)
	# ✅ NEW: Connect item_scale_changed
	pricing_engine.item_scale_changed.connect(_on_item_scale_changed)
	
	_register_all_items()
	_initialize_prices()
	
	emit_signal("shop_initialized", shop_name, _registered_items.size())
	print("✓ Shop '%s' initialized with %d items" % [shop_name, _registered_items.size()])


# ============================================================================
# HELPER FOR PRICINGENGINE
# ============================================================================
# ✅ NEW: Dipanggil PricingEngine untuk cari item
func find_item_by_id(item_id: String) -> DynamicShopItem:
	return _registered_items.get(item_id, null)

# ✅ NEW: Dipanggil PricingEngine untuk get all item IDs
func get_all_item_ids() -> Array:
	return _registered_items.keys()


# ============================================================================
# ITEM REGISTRATION
# ============================================================================
func _register_all_items() -> void:
	_registered_items.clear()
	for item in shop_items:
		if item and item.is_valid():
			_registered_items[item.item_id] = item
			_purchase_history[item.item_id] = 0
			_sell_history[item.item_id] = 0


func register_item(item: DynamicShopItem) -> bool:
	if item == null or not item.is_valid():
		push_error("Cannot register item: invalid item or missing item_id")
		return false
	
	if _registered_items.has(item.item_id):
		push_warning("Item '%s' already registered. Skipping." % item.item_id)
		return false
	
	_registered_items[item.item_id] = item
	_purchase_history[item.item_id] = 0
	_sell_history[item.item_id] = 0
	_calculate_and_store_price(item.item_id)
	
	print("✓ Registered item: %s (%s)" % [item.display_name, item.item_id])
	return true


func get_all_registered_items() -> Array[DynamicShopItem]:
	var items: Array[DynamicShopItem] = []
	for value in _registered_items.values():
		items.append(value as DynamicShopItem)
	return items




# ============================================================================
# PRICE CALCULATION (Dual Category System - Bab 2.2.2)
# ============================================================================
func _calculate_baseline_price(item: DynamicShopItem) -> float:
	#Dual Category Formula:
	#baseline = ((base_worth × item_scale) × category_scale) × sub_category_scale
	#If category or sub_category is null, return 1.0 (no effect)
	var base_worth = item.base_worth
	var item_scale = item.item_scale
	var category_scale = _get_category_scale(item.category)
	var sub_category_scale = _get_category_scale(item.sub_category)
	
	var baseline = ((base_worth * item_scale) * category_scale) * sub_category_scale
	return baseline


func _get_category_scale(category: ShopCategory) -> float:
	#"""Helper: Get scale from ShopCategory Resource (null-safe)"""
	if category == null:
		return 1.0
	return category.category_scale


func _calculate_and_store_price(item_id: String) -> float:
	#"""Calculate final price using PricingEngine and store it"""
	var item = _registered_items.get(item_id)
	if item == null:
		return 0.0
	
	var baseline = _calculate_baseline_price(item)
	var final_price = pricing_engine.calculate_final_price(item, baseline)
	
	_current_prices[item_id] = final_price
	return final_price


func get_current_price(item_id: String) -> float:
	#"""Public API: Get current price for an item"""
	if _current_prices.has(item_id):
		return _current_prices[item_id]
	
	return _calculate_and_store_price(item_id)


func get_all_current_prices() -> Dictionary:
	#"""Get all current prices (useful for UI batch update)"""
	var prices: Dictionary = {}
	for item_id in _registered_items.keys():
		prices[item_id] = get_current_price(item_id)
	return prices


# ============================================================================
# TRANSACTIONS (Purchase & Sell)
# ============================================================================
func purchase_item(item_id: String, quantity: int = 1) -> bool:
	#"""Player buys item from shop - price increases based on demand"""
	var item = _registered_items.get(item_id)
	if item == null:
		push_error("Purchase failed: Item '%s' not found" % item_id)
		return false
	
	if quantity <= 0:
		push_error("Purchase failed: Quantity must be > 0")
		return false
	
	# Get price before update
	var price_per_unit = get_current_price(item_id)
	var total_price = price_per_unit * quantity
	
	# Update purchase history
	_purchase_history[item_id] = _purchase_history.get(item_id, 0) + quantity
	
	
	# Recalculate price
	var new_price = _calculate_and_store_price(item_id)
	
	# Emit signals
	emit_signal("item_purchased", item_id, quantity, total_price)
	emit_signal("price_updated", item_id, new_price)
	
	print("🛒 Purchased %d x %s @ %.2f each = %.2f total" % [quantity, item_id, price_per_unit, total_price])
	print("   New price: %.2f (was %.2f)" % [new_price, price_per_unit])
	
	return true


func sell_item(item_id: String, quantity: int = 1) -> bool:
	#"""Player sells item to shop - price decreases based on supply"""
	var item = _registered_items.get(item_id)
	if item == null:
		push_error("Sell failed: Item '%s' not found" % item_id)
		return false
	
	if quantity <= 0:
		push_error("Sell failed: Quantity must be > 0")
		return false
	
	# Get price before update
	var price_per_unit = get_current_price(item_id)
	var total_price = price_per_unit * quantity
	
	# Update sell history
	_sell_history[item_id] = _sell_history.get(item_id, 0) + quantity
	
	# Recalculate price
	var new_price = _calculate_and_store_price(item_id)
	
	# Emit signals
	emit_signal("item_sold", item_id, quantity, total_price)
	emit_signal("price_updated", item_id, new_price)
	
	print("💰 Sold %d x %s @ %.2f each = %.2f total" % [quantity, item_id, price_per_unit, total_price])
	print("   New price: %.2f (was %.2f)" % [new_price, price_per_unit])
	
	return true


# ============================================================================
# SIGNAL HANDLERS (Response to PricingEngine Events)
# ============================================================================
func _on_item_scale_changed(item_id: String, old_scale: float, new_scale: float) -> void:
	# Called when item_scale is modified directly
	if _registered_items.has(item_id):
		var new_price = _calculate_and_store_price(item_id)
		emit_signal("price_updated", item_id, new_price)
		emit_signal("item_scale_updated", item_id, new_scale)
		print("🏪 Shop '%s' updated item scale: %s (%.2f → %.2f)" % [shop_name, item_id, old_scale, new_scale])

func _on_price_changed(item_id: String, reason: String, multiplier: float) -> void:
	#"""Called when PricingEngine modifies prices"""
	if item_id.is_empty():
		# Global or category change - update all items
		for id in _registered_items.keys():
			var new_price = _calculate_and_store_price(id)
			emit_signal("price_updated", id, new_price)
	else:
		# Specific item change (item_scale sudah di-handle di _on_item_scale_changed)
		if reason != "item_scale" and _registered_items.has(item_id):
			var new_price = _calculate_and_store_price(item_id)
			emit_signal("price_updated", item_id, new_price)
	
	print("🏪 Shop '%s' received price change: %s (%s) x%.2f" % [shop_name, item_id, reason, multiplier])


func _on_category_scale_changed(category: ShopCategory, old_scale: float, new_scale: float) -> void:
	#"""Called when category scale changes - update all items in this category"""
	for item_id in _registered_items.keys():
		var item = _registered_items[item_id]
		if item.category == category or item.sub_category == category:
			var new_price = _calculate_and_store_price(item_id)
			emit_signal("price_updated", item_id, new_price)
	
	print("🏪 Shop '%s' updated all %s items" % [shop_name, category.category_name])


func _on_global_event_triggered(event_name: String, multiplier: float) -> void:
	#"""Called when global event affects all prices"""
	for item_id in _registered_items.keys():
		var new_price = _calculate_and_store_price(item_id)
		emit_signal("price_updated", item_id, new_price)
	
	print("🏪 Shop '%s' responded to global event: %s (x%.2f)" % [shop_name, event_name, multiplier])


# ============================================================================
# UTILITY & DEBUG
# ============================================================================
func get_purchase_count(item_id: String) -> int:
	return _purchase_history.get(item_id, 0)


func get_sell_count(item_id: String) -> int:
	return _sell_history.get(item_id, 0)


func reset_history(item_id: String = "") -> void:
	if item_id.is_empty():
		for key in _purchase_history.keys():
			_purchase_history[key] = 0
			_sell_history[key] = 0
			_calculate_and_store_price(key)
		print("✓ Reset all purchase/sell history")
	else:
		_purchase_history[item_id] = 0
		_sell_history[item_id] = 0
		_calculate_and_store_price(item_id)
		print("✓ Reset history for item: %s" % item_id)


func get_item_count() -> int:
	return _registered_items.size()


func _initialize_prices() -> void:
	for item_id in _registered_items.keys():
		_calculate_and_store_price(item_id)
