class_name PricingEngine
extends Node

# ============================================================================
# SIGNAL (Event-Driven Architecture - Bab 3.2.2.B)
# ============================================================================
signal price_changed(item_id: String, reason: String, multiplier: float)
signal category_scale_changed(category: ShopCategory, old_scale: float, new_scale: float)
signal global_event_triggered(event_name: String, multiplier: float)

# ============================================================================
# DATA STORAGE
# ============================================================================
var _category_scale_overrides: Dictionary = {}  # {category_name: override_multiplier}
var _item_multipliers: Dictionary = {}  # {item_id: current_multiplier}
var _global_multiplier: float = 1.0

# ============================================================================
# CORE API - SIMPLE & INTUITIVE
# ============================================================================

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


## Multiply category scale (relative change)
func multiply_category_scale(category: ShopCategory, multiplier: float) -> void:
	if category == null:
		return
	
	var cat_name = category.category_name.to_upper()
	var current = _category_scale_overrides.get(cat_name, category.category_scale)
	var new_scale = current * multiplier
	
	set_category_scale(category, new_scale)


## Set item value multiplier (for temporary effects like discounts, buffs)
func set_item_multiplier(item_id: String, multiplier: float) -> void:
	var old_multiplier = _item_multipliers.get(item_id, 1.0)
	_item_multipliers[item_id] = multiplier
	
	emit_signal("price_changed", item_id, "item_multiplier", multiplier)
	print("📦 Item '%s' multiplier: %.2f → %.2f" % [item_id, old_multiplier, multiplier])


## Multiply item value (relative change)
func multiply_item_value(item_id: String, multiplier: float) -> void:
	var current = _item_multipliers.get(item_id, 1.0)
	set_item_multiplier(item_id, current * multiplier)


## Reset item multiplier to default
func reset_item_multiplier(item_id: String) -> void:
	set_item_multiplier(item_id, 1.0)


## Trigger global event (affects ALL items worldwide)
func trigger_global_event(event_name: String, multiplier: float) -> void:
	_global_multiplier = multiplier
	emit_signal("global_event_triggered", event_name, multiplier)
	emit_signal("price_changed", "", "global_event_%s" % event_name, multiplier)
	print("🌍 Global Event '%s': All prices x%.2f" % [event_name, multiplier])


# ============================================================================
# HELPER FUNCTIONS (Used by DynamicShop)
# ============================================================================

func get_category_scale(category: ShopCategory) -> float:
	if category == null:
		return 1.0
	
	var cat_name = category.category_name.to_upper()
	
	# Check override first
	if _category_scale_overrides.has(cat_name):
		return category.category_scale * _category_scale_overrides[cat_name]
	
	# Return base scale from ShopCategory Resource
	return category.category_scale


func get_item_multiplier(item_id: String) -> float:
	return _item_multipliers.get(item_id, 1.0)


func get_global_multiplier() -> float:
	return _global_multiplier


# ============================================================================
# PRICE CALCULATION (Delegate from DynamicShop)
# ============================================================================

func calculate_final_price(item: DynamicShopItem, base_price: float) -> float:
	#"""
	#Simplified Formula:
	#final_price = base_price × item_multiplier × global_multiplier
	#
	#Where base_price already includes:
	#base_price = (base_worth × item_scale) × category_scale × sub_category_scale
	#
	#"""
	var item_mult = get_item_multiplier(item.item_id)
	var global_mult = get_global_multiplier()
	
	var final = base_price * item_mult * global_mult
	
	# Clamping (Bab 3.2.2.A) - Prevent extreme prices
	var min_price = base_price * 0.1
	var max_price = base_price * 5.0
	
	return clamp(final, min_price, max_price)

# ============================================================================
# RESET & CLEANUP
# ============================================================================

func reset_item_multipliers(item_id: String = "") -> void:
	if item_id.is_empty():
		_item_multipliers.clear()
		print("✓ Reset all item multipliers")
	else:
		_item_multipliers[item_id] = 1.0
		print("✓ Reset multiplier for item: %s" % item_id)


func reset_category_overrides() -> void:
	_category_scale_overrides.clear()
	print("✓ Reset all category scale overrides")


func reset_all() -> void:
	reset_item_multipliers()
	reset_category_overrides()
	_global_multiplier = 1.0
	print("✓ Pricing Engine fully reset")
