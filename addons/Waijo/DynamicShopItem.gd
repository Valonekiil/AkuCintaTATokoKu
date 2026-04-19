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

# ⭐ FITUR BARU: STOCK TRACKING (Bab 3.2.1 - Resource System Extension)
@export var max_stock: int = 999  # Stok maksimal toko
@export var current_stock: int = 999  # Stok saat ini
@export var restock_rate: float = 0.0  # % restock per menit (0 = tidak restock)
@export var stock_sensitivity: float = 0.5  # Sensitivitas harga terhadap stok (0-1)

# METODE TAMBAHAN
func get_full_name() -> String:
	return "%s (%s)" % [display_name, item_id]

func is_valid() -> bool:
	return !item_id.is_empty() and base_worth > 0

# Helper untuk cek stock status
func get_stock_percentage() -> float:
	if max_stock <= 0:
		return 1.0
	return float(current_stock) / float(max_stock)

func is_out_of_stock() -> bool:
	return current_stock <= 0

func is_overstocked(threshold: float = 0.9) -> bool:
	return get_stock_percentage() >= threshold

func is_low_stock(threshold: float = 0.2) -> bool:
	return get_stock_percentage() <= threshold
