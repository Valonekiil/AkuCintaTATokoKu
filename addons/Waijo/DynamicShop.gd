@tool
class_name DynamicShop
extends Node

# ============================================================================
# SIGNAL
# ============================================================================
signal item_purchased(item_id: String, quantity: int, final_price: float)
signal item_sold(item_id: String, quantity: int, final_price: float)
signal price_updated(item_id: String, new_price: float)
signal shop_initialized(shop_name: String, item_count: int)

# ============================================================================
# KONFIGURASI
# ============================================================================
@export var shop_name: String = "General Store"
@export var shop_items: Array[DynamicShopItem] = []
@export var union_id: String = ""  # Empty = auto-generate unique ID
@export var isolated: bool = false  # true = no signal connections at all

# ============================================================================
# DATA RUNTIME (Setiap shop punya COPY sendiri)
# ============================================================================
var _registered_items: Dictionary = {}  # {item_id: DynamicShopItem COPY}
var _current_prices: Dictionary = {}  # {item_id: current_price}

# Reference ke SignalManager
var signal_manager: SignalManagerClass = null


# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
    # Get SignalManager singleton
    signal_manager = get_node_or_null("/root/SignalManager")
    
    if signal_manager == null:
        push_warning("⚠️ SignalManager not found! Creating temporary instance...")
        signal_manager = SignalManagerClass.new()
    
    # Auto-generate unique union_id jika kosong
    if union_id.is_empty():
        union_id = "Union_%s_%s" % [shop_name, get_instance_id()]
        print("🆔 Auto-generated union_id: %s" % union_id)
    
    # Create COPIES of all items (bukan reference langsung!)
    _create_item_copies()
    
    # Connect to signals HANYA jika tidak isolated
    if not isolated:
        _connect_to_signals()
    else:
        print("🔒 Shop '%s' is ISOLATED - no signal connections" % shop_name)
    
    # Initialize prices
    _initialize_prices()
    
    emit_signal("shop_initialized", shop_name, _registered_items.size())
    print("✓ Shop '%s' (Union: %s) initialized with %d items" % [shop_name, union_id, _registered_items.size()])


func _exit_tree() -> void:
    # Disconnect signals saat shop dihapus
    if signal_manager:
        signal_manager.disconnect_shop(self)


# ============================================================================
# ITEM COPY SYSTEM (Kunci Modularitas!)
# ============================================================================
func _create_item_copies() -> void:
    _registered_items.clear()
    for item in shop_items:
        if item and item.is_valid():
            # ✅ DEEP COPY Resource - setiap shop punya versi sendiri!
            var item_copy = item.duplicate()
            _registered_items[item.item_id] = item_copy
            print("  📦 Created copy: %s (item_scale: %.2f)" % [item.item_id, item_copy.item_scale])


func get_all_registered_items() -> Array[DynamicShopItem]:
    var items: Array[DynamicShopItem] = []
    for value in _registered_items.values():
        items.append(value as DynamicShopItem)
    return items


func find_item_by_id(item_id: String) -> DynamicShopItem:
    return _registered_items.get(item_id, null)


# ============================================================================
# SIGNAL CONNECTION (Based on Union ID)
# ============================================================================
func _connect_to_signals() -> void:
    if signal_manager == null:
        return
    
    # Connect ke global signal (semua shop receive)
    signal_manager.connect_shop_to_global(self)
    
    # Connect ke union signal (hanya shop dengan union_id sama)
    if union_id != "":
        signal_manager.connect_shop_to_union(self, union_id)
        print("✓ Shop '%s' listening to union: %s" % [shop_name, union_id])


# ============================================================================
# RUNTIME UNION CHANGE (Dynamic Faction Switching)
# ============================================================================
func set_union_id(new_union_id: String) -> void:
    # Disconnect dari union lama
    if signal_manager:
        signal_manager.disconnect_shop(self, union_id)
    
    # Update union_id (auto-generate jika empty)
    union_id = new_union_id if not new_union_id.is_empty() else "Union_%s_%s" % [shop_name, get_instance_id()]
    
    # Reconnect ke union baru (hanya jika tidak isolated)
    if signal_manager and not isolated:
        signal_manager.connect_shop_to_union(self, union_id)
    
    print("🔄 Shop '%s' changed union: %s" % [shop_name, union_id])


func set_isolated(new_isolated: bool) -> void:
    isolated = new_isolated
    
    if isolated:
        # Disconnect semua signal
        if signal_manager:
            signal_manager.disconnect_shop(self, union_id)
        print("🔒 Shop '%s' now ISOLATED" % shop_name)
    else:
        # Connect signals
        _connect_to_signals()
        print("🔓 Shop '%s' now CONNECTED" % shop_name)


# ============================================================================
# SIGNAL HANDLERS (Dipanggil oleh SignalManager)
# ============================================================================
func _on_union_scale_changed(union_id_param: String, item_id: String, modifier: float) -> void:
    # Hanya process jika union_id match
    if union_id_param != union_id:
        return
    
    _modify_item_scale(item_id, modifier)


func _on_global_scale_changed(item_id: String, modifier: float) -> void:
    # Semua shop receive global signal
    _modify_item_scale(item_id, modifier)


func _on_global_category_changed(category_name: String, modifier: float) -> void:
    # Update category scale untuk semua item dalam kategori ini
    for item_id in _registered_items.keys():
        var item = _registered_items[item_id]
        if item.category and item.category.category_name.to_upper() == category_name.to_upper():
            # Modify category scale (perlu akses ke ShopCategory Resource)
            item.category.category_scale += modifier
    
    # Recalculate all prices
    for item_id in _registered_items.keys():
        var new_price = _calculate_and_store_price(item_id)
        emit_signal("price_updated", item_id, new_price)
    
    print("🏪 Shop '%s' updated category: %s" % [shop_name, category_name])


# ============================================================================
# PRICE MODIFICATION (Direct Resource Modification)
# ============================================================================
func _modify_item_scale(item_id: String, modifier: float) -> void:
    if not _registered_items.has(item_id):
        return
    
    var item = _registered_items[item_id]
    var old_scale = item.item_scale
    item.item_scale += modifier
    item.item_scale = max(item.item_scale, 0.1)  # Min clamp
    
    print("📦 Shop '%s' modified %s scale: %.2f → %.2f" % [shop_name, item_id, old_scale, item.item_scale])
    
    # Recalculate price
    var new_price = _calculate_and_store_price(item_id)
    emit_signal("price_updated", item_id, new_price)


func _calculate_baseline_price(item: DynamicShopItem) -> float:
    var cat_scale = item.category.category_scale if item.category else 1.0
    var sub_cat_scale = item.sub_category.category_scale if item.sub_category else 1.0
    return (item.base_worth * item.item_scale) * cat_scale * sub_cat_scale


func _calculate_and_store_price(item_id: String) -> float:
    var item = _registered_items.get(item_id)
    if item == null:
        return 0.0
    
    var baseline = _calculate_baseline_price(item)
    
    # Clamping (Bab 3.2.2.A)
    var min_price = baseline * 0.3
    var max_price = baseline * 3.0
    
    _current_prices[item_id] = clamp(baseline, min_price, max_price)
    return _current_prices[item_id]


func get_current_price(item_id: String) -> float:
    if _current_prices.has(item_id):
        return _current_prices[item_id]
    return _calculate_and_store_price(item_id)


func _initialize_prices() -> void:
    for item_id in _registered_items.keys():
        _calculate_and_store_price(item_id)


# ============================================================================
# TRANSACTIONS
# ============================================================================
func purchase_item(item_id: String, quantity: int = 1) -> bool:
    var item = _registered_items.get(item_id)
    if item == null:
        push_error("Purchase failed: Item '%s' not found" % item_id)
        return false
    
    if quantity <= 0:
        push_error("Purchase failed: Quantity must be > 0")
        return false
    
    var price_per_unit = get_current_price(item_id)
    var total_price = price_per_unit * quantity
    
    # ✅ HAPUS: Tidak ada purchase_history lagi!
    # Harga TIDAK otomatis berubah saat beli (kecuali via SignalManager)
    
    emit_signal("item_purchased", item_id, quantity, total_price)
    print("🛒 Purchased %d x %s @ %.2f = %.2f" % [quantity, item_id, price_per_unit, total_price])
    
    return true


func sell_item(item_id: String, quantity: int = 1) -> bool:
    var item = _registered_items.get(item_id)
    if item == null:
        push_error("Sell failed: Item '%s' not found" % item_id)
        return false
    
    if quantity <= 0:
        push_error("Sell failed: Quantity must be > 0")
        return false
    
    var price_per_unit = get_current_price(item_id)
    var total_price = price_per_unit * quantity
    
    # ✅ HAPUS: Tidak ada sell_history lagi!
    
    emit_signal("item_sold", item_id, quantity, total_price)
    print("💰 Sold %d x %s @ %.2f = %.2f" % [quantity, item_id, price_per_unit, total_price])
    
    return true


# ============================================================================
# UTILITY
# ============================================================================
func get_item_count() -> int:
    return _registered_items.size()


func reset_all_scales() -> void:
    # Reset ke original scale (dari resource template)
    for i in range(shop_items.size()):
        var original = shop_items[i]
        var copy = _registered_items.get(original.item_id)
        if copy:
            copy.item_scale = original.item_scale
    
    # Recalculate prices
    for item_id in _registered_items.keys():
        _calculate_and_store_price(item_id)
    
    print("✓ Shop '%s' reset all item scales" % shop_name)
