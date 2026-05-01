class_name SignalManagerClass
extends Node

# ============================================================================
# SIGNAL DEFINITIONS
# ============================================================================
signal union_item_scale_changed(union_id: String, item_id: String, modifier: float)
signal global_item_scale_changed(item_id: String, modifier: float)
signal global_category_changed(category_name: String, modifier: float)

# ============================================================================
# CORE API
# ============================================================================

## Emit signal ke toko-toko dalam union tertentu
func emit_union_scale_change(union_id: String, item_id: String, modifier: float) -> void:
    emit_signal("union_item_scale_changed", union_id, item_id, modifier)
    print("📢 Union Signal: %s → %s (%+.2f)" % [union_id, item_id, modifier])


## Emit signal ke SEMUA toko (global event)
func emit_global_scale_change(item_id: String, modifier: float) -> void:
    emit_signal("global_item_scale_changed", item_id, modifier)
    print("🌍 Global Signal: %s (%+.2f)" % [item_id, modifier])


## Emit signal untuk category change (global)
func emit_global_category_change(category_name: String, modifier: float) -> void:
    emit_signal("global_category_changed", category_name, modifier)
    print("🏷️ Global Category: %s (%+.2f)" % [category_name, modifier])


## Helper: Connect shop ke union signal
func connect_shop_to_union(shop: Node, union_id: String) -> void:
    if not union_item_scale_changed.is_connected(shop._on_union_scale_changed.bind(union_id)):
        union_item_scale_changed.connect(shop._on_union_scale_changed.bind(union_id))
    print("✓ Shop connected to union: %s" % union_id)


## Helper: Connect shop ke global signal
func connect_shop_to_global(shop: Node) -> void:
    if not global_item_scale_changed.is_connected(shop._on_global_scale_changed):
        global_item_scale_changed.connect(shop._on_global_scale_changed)
    if not global_category_changed.is_connected(shop._on_global_category_changed):
        global_category_changed.connect(shop._on_global_category_changed)
    print("✓ Shop connected to global signals")


## Helper: Disconnect shop dari semua signal
func disconnect_shop(shop: Node) -> void:
    if union_item_scale_changed.is_connected(shop._on_union_scale_changed.bind(shop.union_id)):
        union_item_scale_changed.disconnect(shop._on_union_scale_changed.bind(shop.union_id))
    if global_item_scale_changed.is_connected(shop._on_global_scale_changed):
        global_item_scale_changed.disconnect(shop._on_global_scale_changed)
    if global_category_changed.is_connected(shop._on_global_category_changed):
        global_category_changed.disconnect(shop._on_global_category_changed)
    print("✓ Shop disconnected from signals")
