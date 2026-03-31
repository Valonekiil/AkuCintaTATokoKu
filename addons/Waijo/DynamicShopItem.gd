@tool
class_name DynamicShopItem
extends Resource

# IDENTITAS BARANG
@export var item_id: String = "item_001"  # ID unik untuk identifikasi
@export var display_name: String = "New Item"  # Nama yang ditampilkan di game
# NILAI DASAR BARANG
@export var base_worth: float = 100.0  # Harga dasar/nilai intrinsik barang
# SKALA PENYESUAIAN HARGA
@export_range(0.1, 5.0) var item_scale: float = 1.0  # Pengali kualitas item
@export var category: String = "General"  # Kategori barang (Weapon, Potion, dll)
# PROPERTI UNTUK DYNAMIC PRICING
@export_range(0.1, 5.0) var price_elasticity: float = 1.0  # Responsivitas harga terhadap permintaan
@export_range(0.0, 1.0) var base_demand_impact: float = 0.001  # Dampak dasar per pembelian
# INFORMASI TAMBAHAN
@export var description: String = "A generic item"
@export var icon: Texture2D  # Icon barang untuk UI

# METODE TAMBAHAN
func get_full_name() -> String:
	return "%s (%s)" % [display_name, item_id]

func is_valid() -> bool:
	return !item_id.is_empty() and base_worth > 0
