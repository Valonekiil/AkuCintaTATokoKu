@tool
class_name DynamicShopItem
extends Resource

# ============================================================================
# IDENTITAS BARANG
# ============================================================================
@export var item_id: String = "item_001"
@export var display_name: String = "New Item"

# ============================================================================
# NILAI DASAR BARANG
# ============================================================================
@export var base_worth: float = 100.0
@export_range(0.1, 5.0) var item_scale: float = 1.0

# ============================================================================
# KATEGORI
# ============================================================================
@export var category: ShopCategory
@export var sub_category: ShopCategory

# ============================================================================
# INFORMASI TAMBAHAN
# ============================================================================
@export var description: String = "A generic item"
@export var icon: Texture2D

# ============================================================================
# METODE
# ============================================================================
func get_full_name() -> String:
    return "%s (%s)" % [display_name, item_id]

func is_valid() -> bool:
    return !item_id.is_empty() and base_worth > 0

func get_baseline_price() -> float:
    var cat_scale = category.category_scale if category else 1.0
    var sub_cat_scale = sub_category.category_scale if sub_category else 1.0
    return (base_worth * item_scale) * cat_scale * sub_cat_scale
