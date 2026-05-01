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
    if union_id.is_empty():
        push_warning("⚠️ Cannot connect to empty union_id!")
        return
    
    var callable = Callable(shop, "_on_union_scale_changed").bind(union_id)
    
    # Disconnect dulu jika sudah connected (prevent duplicate)
    if union_item_scale_changed.is_connected(callable):
        union_item_scale_changed.disconnect(callable)
    
    union_item_scale_changed.connect(callable)
    print("✓ Shop connected to union: %s" % union_id)


## Helper: Connect shop ke global signal
func connect_shop_to_global(shop: Node) -> void:
    if not global_item_scale_changed.is_connected(shop._on_global_scale_changed):
        global_item_scale_changed.connect(shop._on_global_scale_changed)
    if not global_category_changed.is_connected(shop._on_global_category_changed):
        global_category_changed.connect(shop._on_global_category_changed)
    print("✓ Shop connected to global signals")


## Helper: Disconnect shop dari semua signal
func disconnect_shop(shop: Node, union_id: String = "") -> void:
    # Disconnect dari union signal (gunakan union_id yang diberikan atau dari shop)
    var target_union_id = union_id if not union_id.is_empty() else shop.union_id
    
    if not target_union_id.is_empty():
        var union_callable = Callable(shop, "_on_union_scale_changed").bind(target_union_id)
        if union_item_scale_changed.is_connected(union_callable):
            union_item_scale_changed.disconnect(union_callable)
    
    # Disconnect dari global signals
    var global_callable = Callable(shop, "_on_global_scale_changed")
    var category_callable = Callable(shop, "_on_global_category_changed")
    
    if global_item_scale_changed.is_connected(global_callable):
        global_item_scale_changed.disconnect(global_callable)
    if global_category_changed.is_connected(category_callable):
        global_category_changed.disconnect(category_callable)
    
    print("✓ Shop disconnected from signals")
