class_name PricingEngine
extends Node

# ============================================================================
# SIGNAL (Event-Driven Architecture - Bab 3.2.2.B)
# ============================================================================
signal price_changed(item_id: String, reason: String, multiplier: float)
signal category_scale_changed(category: ShopCategory, old_scale: float, new_scale: float)
signal global_event_triggered(event_name: String, multiplier: float)
signal item_scale_changed(item_id: String, old_scale: float, new_scale: float)  # ✅ NEW

# ============================================================================
# DATA STORAGE
# ============================================================================
var _category_scale_overrides: Dictionary = {}  # {category_name: override_multiplier}
# ❌ HAPUS: var _item_multipliers: Dictionary = {}  # Nggak perlu lagi!
var _global_multiplier: float = 1.0

# ============================================================================
# CORE API - MODIFIKASI ITEM_SCALE LANGSUNG
# ============================================================================

## ✅ NEW: Set item_scale langsung di Resource
func set_item_scale(item_id: String, new_scale: float) -> void:
	var item = _find_item_by_id(item_id)
	if item == null:
		push_warning("⚠️ Item '%s' not found" % item_id)
		return
	
	var old_scale = item.item_scale
	item.item_scale = new_scale
	
	emit_signal("item_scale_changed", item_id, old_scale, new_scale)
	emit_signal("price_changed", item_id, "item_scale", new_scale)
	
	print("📦 Item '%s' scale: %.2f → %.2f" % [item_id, old_scale, new_scale])

## ✅ NEW: Modify item_scale (relative change)
func modify_item_scale(item_id: String, modifier: float) -> void:
	var item = _find_item_by_id(item_id)
	if item == null:
		return
	
	var old_scale = item.item_scale
	var new_scale = old_scale + modifier
	new_scale = max(new_scale, 0.1)  # Min clamp 0.1
	item.item_scale = new_scale
	
	emit_signal("item_scale_changed", item_id, old_scale, new_scale)
	emit_signal("price_changed", item_id, "item_scale", new_scale)
	
	print("📦 Item '%s' scale modified: %.2f → %.2f" % [item_id, old_scale, new_scale])

## ✅ NEW: Reset item_scale ke original
func reset_item_scale(item_id: String) -> void:
	var item = _find_item_by_id(item_id)
	if item == null:
		return
	
	var old_scale = item.item_scale
	item.reset_item_scale()
	
	emit_signal("item_scale_changed", item_id, old_scale, item.item_scale)
	emit_signal("price_changed", item_id, "reset", item.item_scale)
	
	print("📦 Item '%s' scale reset to: %.2f" % [item_id, item.item_scale])

## ✅ NEW: Reset semua item scales
func reset_all_item_scales() -> void:
	for item_id in _get_all_item_ids():
		reset_item_scale(item_id)
	print("✓ Reset all item scales")

## Set category scale directly (override base scale from ShopCategory Resource)
func set_category_scale(category: ShopCategory, new_scale: float) -> void:
	if category == null:
		push_warning("⚠️ Cannot set scale: category is null")
		return
	
	var cat_name = category.category_name.to_upper()
	var old_scale = _category_scale_overrides.get(cat_name, category.category_scale)
	
	_category_scale_overrides[cat_name] = new_scale
	
	emit_signal("category_scale_changed", category, old_scale, new_scale)
	emit_signal("price_changed", "", "category_%s" % cat_name, new_scale)
	
	print("🏷️ Category '%s' scale: %.2f → %.2f" % [cat_name, old_scale, new_scale])

func modify_category_scale(category: ShopCategory, modifier: float) -> void:
	if category == null:
		push_warning("⚠️ Cannot set scale: category is null")
		return
	
	var cat_name = category.category_name.to_upper()
	var old_scale = _category_scale_overrides.get(cat_name, category.category_scale)
	var new_scale = old_scale + modifier
	_category_scale_overrides[cat_name] = new_scale
	
	emit_signal("category_scale_changed", category, old_scale, new_scale)
	emit_signal("price_changed", "", "category_%s" % cat_name, new_scale)
	
	print("🏷️ Category '%s' scale: %.2f → %.2f" % [cat_name, old_scale, new_scale])

## Multiply category scale (relative change)
func multiply_category_scale(category: ShopCategory, multiplier: float) -> void:
	if category == null:
		return
	
	var cat_name = category.category_name.to_upper()
	var current = _category_scale_overrides.get(cat_name, category.category_scale)
	var new_scale = current * multiplier
	
	set_category_scale(category, new_scale)


## Trigger global event (affects ALL items worldwide)
func trigger_global_event(event_name: String, multiplier: float) -> void:
	_global_multiplier = multiplier
	emit_signal("global_event_triggered", event_name, multiplier)
	emit_signal("price_changed", "", "global_event_%s" % event_name, multiplier)
	print("🌍 Global Event '%s': All prices x%.2f" % [event_name, multiplier])


# ============================================================================
# HELPER FUNCTIONS (Used by DynamicShop)
# ============================================================================

func _find_item_by_id(item_id: String) -> DynamicShopItem:
	# Cari dari semua Resource DynamicShopItem yang ada
	# Note: Ini perlu akses ke registry item (bisa dari DynamicShop)
	# Untuk sekarang, return null — DynamicShop yang handle
	return null

func _get_all_item_ids() -> Array:
	# Return semua item_id yang terdaftar
	# DynamicShop yang handle ini
	return []

func get_category_scale(category: ShopCategory) -> float:
	if category == null:
		return 1.0
	
	var cat_name = category.category_name.to_upper()
	
	# Check override first
	if _category_scale_overrides.has(cat_name):
		return category.category_scale * _category_scale_overrides[cat_name]
	
	# Return base scale from ShopCategory Resource
	return category.category_scale


func get_global_multiplier() -> float:
	return _global_multiplier


# ============================================================================
# PRICE CALCULATION (Delegate from DynamicShop)
# ============================================================================

func calculate_final_price(item: DynamicShopItem, base_price: float) -> float:
	# Simplified: item_scale sudah termasuk di base_price
	# base_price = (base_worth × item_scale) × category_scale × sub_category_scale
	var global_mult = get_global_multiplier()
	var final = base_price * global_mult
	
	# Clamping (Bab 3.2.2.A) - Prevent extreme prices
	var min_price = base_price * 0.1
	var max_price = base_price * 5.0
	
	return clamp(final, min_price, max_price)

# ============================================================================
# RESET & CLEANUP
# ============================================================================

func reset_category_overrides() -> void:
	_category_scale_overrides.clear()
	print("✓ Reset all category scale overrides")

func reset_all() -> void:
	reset_all_item_scales()
	reset_category_overrides()
	_global_multiplier = 1.0
	print("✓ Pricing Engine fully reset")
