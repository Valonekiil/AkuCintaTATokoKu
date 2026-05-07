class_name SignalManagerClass
extends Node

# ============================================================================
# SIGNAL (Untuk UI & External Systems)
# ============================================================================
signal group_scale_changed(group_id: String, item_id: String, modifier: float)
signal global_scale_changed(item_id: String, modifier: float)
signal global_category_changed(category_name: String, modifier: float)

# ============================================================================
# DATA STORAGE (Track Shops by Group)
# ============================================================================
var _group_shops: Dictionary = {}  # {group_id: [shop1, shop2, ...]}
var _global_shops: Array = []  # All shops that receive global events


# ============================================================================
# REGISTRATION
# ============================================================================
func register_shop(shop: Node, group_id: String, is_isolated: bool = false) -> void:
	if is_isolated:
		print("🔒 Shop '%s' is ISOLATED - not registered" % shop.shop_name)
		return
	
	# Register to group (ONLY if group_id is NOT empty)
	if not group_id.is_empty():
		if not _group_shops.has(group_id):
			_group_shops[group_id] = []
		if not _group_shops[group_id].has(shop):
			_group_shops[group_id].append(shop)
			print("✓ Shop '%s' registered to group: %s" % [shop.shop_name, group_id])
	
	# Always register for global events (unless isolated)
	if not _global_shops.has(shop):
		_global_shops.append(shop)
		print("✓ Shop '%s' registered to global events" % shop.shop_name)


func unregister_shop(shop: Node, group_id: String) -> void:
	# Remove from group
	if not group_id.is_empty() and _group_shops.has(group_id):
		_group_shops[group_id].erase(shop)
		if _group_shops[group_id].is_empty():
			_group_shops.erase(group_id)
	
	# Remove from global
	_global_shops.erase(shop)
	
	print("✓ Shop '%s' unregistered" % shop.shop_name)


# ============================================================================
# EMIT FUNCTIONS (Direct Call - NO SIGNAL for Group!)
# ============================================================================
func emit_group_scale_change(group_id: String, item_id: String, modifier: float) -> void:
	print("📢 Group Signal: %s → %s (%+.2f)" % [group_id, item_id, modifier])
	
	if not _group_shops.has(group_id):
		print("⚠️ No shops in group: %s" % group_id)
		return
	
	# ✅ DIRECT CALL ke semua shop dalam group
	for shop in _group_shops[group_id]:
		if is_instance_valid(shop):
			shop._on_group_scale_changed(group_id, item_id, modifier)


func emit_global_scale_change(item_id: String, modifier: float) -> void:
	print("🌍 Global Signal: %s (%+.2f)" % [item_id, modifier])
	
	# ✅ DIRECT CALL ke semua global shops
	for shop in _global_shops:
		if is_instance_valid(shop):
			shop._on_global_scale_changed(item_id, modifier)


func emit_global_category_change(category_name: String, modifier: float) -> void:
	print("🏷️ Global Category: %s (%+.2f)" % [category_name, modifier])
	
	for shop in _global_shops:
		if is_instance_valid(shop):
			shop._on_global_category_changed(category_name, modifier)


# ============================================================================
# UTILITY
# ============================================================================
func get_group_shop_count(group_id: String) -> int:
	return _group_shops.get(group_id, []).size()


func get_total_registered_shops() -> int:
	return _global_shops.size()
