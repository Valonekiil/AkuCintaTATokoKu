@tool
class_name DynamicShop
extends Node

# PROPETI KONFIGURASI
@export var shop_name: String = "General Store"  # Nama toko
@export var shop_items: Array[DynamicShopItem] = []  # Daftar barang yang dijual

# PROPETI RUNTIME
var _registered_items: Dictionary = {}  # {item_id: DynamicShopItem}
var _purchase_history: Dictionary = {}  # {item_id: total_quantity_purchased}

# SIGNALS (EVENT SYSTEM)
signal item_registered(item_id: String, item: DynamicShopItem)
signal item_purchased(item_id: String, quantity: int, total_price: float)
signal price_updated(item_id: String, new_price: float)

# FUNGSI INTI: MENDAFTARKAN BARANG
func register_item(item: DynamicShopItem) -> bool:
	# Validasi item
	if item == null:
		push_error("Cannot register item: item is null")
		return false
	
	if item.item_id.is_empty():
		push_error("Cannot register item: missing item_id")
		return false
	
	# Cek duplikasi
	if _registered_items.has(item.item_id):
		push_warning("Item '%s' already registered. Skipping." % item.item_id)
		return false
	
	# Daftarkan item
	_registered_items[item.item_id] = item
	_purchase_history[item.item_id] = 0
	
	# Emit signal
	emit_signal("item_registered", item.item_id, item)
	
	print("✓ Registered item: %s (%s)" % [item.display_name, item.item_id])
	return true

# FUNGSI INTI: MENDAPATKAN SEMUA BARANG
func get_all_registered_items() -> Array[DynamicShopItem]:
	var items: Array[DynamicShopItem] = []
	for item in _registered_items.values():
		items.append(item as DynamicShopItem)
	return items

# FUNGSI INTI: MENCARI BARANG BERDASARKAN ID
func find_item_by_id(item_id: String) -> DynamicShopItem:
	return _registered_items.get(item_id, null)

# FUNGSI INTI: MENDAPATKAN JUMLAH ITEM TERDAFTAR
func get_item_count() -> int:
	return _registered_items.size()

# FUNGSI INTI: MENDAPATKAN RIWAYAT PEMBELIAN
func get_purchase_count(item_id: String) -> int:
	return _purchase_history.get(item_id, 0)

# LIFECYCLE: OTOMATIS MENDAFTARKAN BARANG
func _ready():
	# Mendaftarkan semua item dari array shop_items yang dikonfigurasi di Editor
	for item in shop_items:
		register_item(item)
	var sc = self.name
	print("Shop '%s' initialized with %d items, and from " % [shop_name, get_item_count()], sc)

# DEBUG: MENAMPILKAN INFO TOKO
func debug_print_shop_info():
	print("\n=== SHOP INFO: %s ===" % shop_name)
	print("Total items: %d" % get_item_count())
	print("Items:")
	for item_id in _registered_items:
		var item = _registered_items[item_id]
		var purchases = _purchase_history[item_id]
		print("  - %s: base_worth=%.2f, scale=%.2f, purchased=%d times" % [
			item.display_name, item.base_worth, item.item_scale, purchases
		])
	print("========================\n")
