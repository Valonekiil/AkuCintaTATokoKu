@tool
class_name DynamicShop
extends Node

# ============================================================================
# SIGNAL (Event-Driven Architecture - Bab 3.2.2.B)
# ============================================================================
signal item_purchased(item_id: String, quantity: int, final_price: float)
signal item_sold(item_id: String, quantity: int, final_price: float)
signal price_updated(item_id: String, new_price: float)
signal shop_initialized(shop_name: String, item_count: int)

# ============================================================================
# KONFIGURASI (Di-set via Inspector)
# ============================================================================
@export var shop_name: String = "General Store"
@export var shop_items: Array[DynamicShopItem] = []

# Kategori global scale (Multiplicative Sampling - Bab 2.2.2)
@export var category_scales: Dictionary = {
	"POTION": 1.0,
	"WEAPON": 1.5,
	"ARMOR": 1.3,
	"FOOD": 0.8,
	"FISH": 0.9,
	"JUNK": 0.5,
	"GENERAL": 1.0
}

# ============================================================================
# DATA RUNTIME (Tidak Diekspor)
# ============================================================================
var _registered_items: Dictionary = {}  # {item_id: DynamicShopItem}
var _purchase_history: Dictionary = {}  # {item_id: purchase_count}
var _sell_history: Dictionary = {}      # {item_id: sell_count}
var _current_prices: Dictionary = {}    # {item_id: current_price}

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	_register_all_items()
	_initialize_prices()
	emit_signal("shop_initialized", shop_name, _registered_items.size())
	print("✓ Shop '%s' initialized with %d items" % [shop_name, _registered_items.size()])


# ============================================================================
# FUNGSI INTI: REGISTRASI ITEM
# ============================================================================
func _register_all_items() -> void:
	_registered_items.clear()
	for item in shop_items:
		if item and not item.item_id.is_empty():
			_registered_items[item.item_id] = item
			_purchase_history[item.item_id] = 0
			_sell_history[item.item_id] = 0


func register_item(item: DynamicShopItem) -> bool:
	if item == null or item.item_id.is_empty():
		push_error("Cannot register item: invalid item or missing item_id")
		return false
	
	if _registered_items.has(item.item_id):
		push_warning("Item '%s' already registered. Skipping." % item.item_id)
		return false
	
	_registered_items[item.item_id] = item
	_purchase_history[item.item_id] = 0
	_sell_history[item.item_id] = 0
	_calculate_and_store_price(item.item_id)
	
	print("✓ Registered item: %s (%s)" % [item.display_name, item.item_id])
	return true


func get_all_registered_items() -> Array[DynamicShopItem]:
	var items: Array[DynamicShopItem] = []
	for value in _registered_items.values():
		items.append(value as DynamicShopItem)
	return items


func find_item_by_id(item_id: String) -> DynamicShopItem:
	return _registered_items.get(item_id, null)


# ============================================================================
# ALGORITMA 1: MULTIPLICATIVE SAMPLING (Bab 2.2.2)
# ============================================================================
# Rumus: current_price = (base_worth × item_scale) × category_scale
	#Contoh: (100 × 0.95) × 1.0 = 95
func _calculate_baseline_price(item: DynamicShopItem) -> float:
	var base_worth = item.base_worth
	var item_scale = item.item_scale
	var category_scale = _get_category_scale(item.category)
	
	var baseline = (base_worth * item_scale) * category_scale
	return baseline


func _get_category_scale(category: String) -> float:
	#Mengambil scale dari dictionary category_scales.
	#Jika kategori tidak ditemukan, return 1.0 (default)
	var upper_category = category.to_upper()
	return category_scales.get(upper_category, 1.0)


# ============================================================================
# ALGORITMA 2: PRICE ELASTICITY DENGAN EFEK KUMULATIF NON-LINEAR (Bab 2.2.2)
# ============================================================================
	#Rumus: effective_demand_impact = base_impact × (n ^ (1 / price_elasticity))
	#
	#Dimana:
	#- n = jumlah pembelian (purchase_count)
	#- base_impact = base_demand_impact dari item
	#- price_elasticity = elastisitas item (>1: elastis, <1: inelastis)
	#
	#Barang Inelastis (elasticity < 1.0):
	#- exponent > 1.0 (contoh: 1/0.3 = 3.33)
	#- Dampak awal besar, lalu melambat (kurva eksponensial)
	#
	#Barang Elastis (elasticity > 1.0):
	#- exponent < 1.0 (contoh: 1/2.0 = 0.5)
	#- Dampak awal kecil, lalu meningkat (kurva akar)
func _calculate_demand_impact(item: DynamicShopItem) -> float:
	var item_id = item.item_id
	var n = _purchase_history.get(item_id, 0)
	
	if n <= 0:
		return 0.0
	
	var exponent = 1.0 / item.price_elasticity
	var impact = item.base_demand_impact * pow(n, exponent)
	
	return impact


	#Rumus sama dengan demand_impact, tapi untuk penjualan.
	#Penjualan menurunkan harga (impact negatif)
func _calculate_sell_impact(item: DynamicShopItem) -> float:
	var item_id = item.item_id
	var n = _sell_history.get(item_id, 0)
	
	if n <= 0:
		return 0.0
	
	var exponent = 1.0 / item.price_elasticity
	var impact = item.base_demand_impact * pow(n, exponent)
	
	return impact


# ============================================================================
# FUNGSI INTEGRASI: HARGA FINAL
# ============================================================================
	#Menghitung harga final dan menyimpannya ke _current_prices.
	#Rumus: final_price = baseline × (1 + demand_impact - sell_impact)
	#Dengan clamping untuk mencegah harga ekstrem.
func _calculate_and_store_price(item_id: String) -> float:
	var item = _registered_items.get(item_id)
	if item == null:
		return 0.0
	
	var baseline = _calculate_baseline_price(item)
	var demand_impact = _calculate_demand_impact(item)
	var sell_impact = _calculate_sell_impact(item)
	
	# Integrasi: demand naikkan harga, sell turunkan harga
	var price_multiplier = 1.0 + demand_impact - sell_impact
	
	# Clamping: harga tidak boleh < 30% atau > 300% dari baseline (Bab 3.2.2.A)
	var min_price = baseline * 0.3
	var max_price = baseline * 3.0
	
	var final_price = clamp(baseline * price_multiplier, min_price, max_price)
	_current_prices[item_id] = final_price
	
	return final_price

	#Public API untuk mendapatkan harga terkini sebuah item.
func get_current_price(item_id: String) -> float:
	if _current_prices.has(item_id):
		return _current_prices[item_id]
	
	# Jika belum ada, hitung dulu
	return _calculate_and_store_price(item_id)

	#Mendapatkan semua harga saat ini.
	#Berguna untuk UI yang perlu refresh semua item sekaligus.
func get_all_current_prices() -> Dictionary:
	var prices: Dictionary = {}
	for item_id in _registered_items.keys():
		prices[item_id] = get_current_price(item_id)
	return prices


# ============================================================================
# TRANSAKSI: BELI & JUAL
# ============================================================================
	#Pemain membeli item dari toko.
	#- Harga naik berdasarkan demand_impact
	#- Emit signal untuk UI update
func purchase_item(item_id: String, quantity: int = 1) -> bool:
	var item = _registered_items.get(item_id)
	if item == null:
		push_error("Purchase failed: Item '%s' not found" % item_id)
		return false
	
	if quantity <= 0:
		push_error("Purchase failed: Quantity must be > 0")
		return false
	
	# Hitung harga sebelum update history
	var price_per_unit = get_current_price(item_id)
	var total_price = price_per_unit * quantity
	
	# Update history pembelian
	_purchase_history[item_id] = _purchase_history.get(item_id, 0) + quantity
	
	# Recalculate harga setelah pembelian
	var new_price = _calculate_and_store_price(item_id)
	
	# Emit signals
	emit_signal("item_purchased", item_id, quantity, total_price)
	emit_signal("price_updated", item_id, new_price)
	
	print("🛒 Purchased %d x %s @ %.2f each = %.2f total" % [quantity, item_id, price_per_unit, total_price])
	print("   New price: %.2f (was %.2f)" % [new_price, price_per_unit])
	
	return true

	#Pemain menjual item ke toko.
	#- Harga turun berdasarkan sell_impact
	#- Emit signal untuk UI update
func sell_item(item_id: String, quantity: int = 1) -> bool:
	var item = _registered_items.get(item_id)
	if item == null:
		push_error("Sell failed: Item '%s' not found" % item_id)
		return false
	
	if quantity <= 0:
		push_error("Sell failed: Quantity must be > 0")
		return false
	
	# Hitung harga sebelum update history
	var price_per_unit = get_current_price(item_id)
	var total_price = price_per_unit * quantity
	
	# Update history penjualan
	_sell_history[item_id] = _sell_history.get(item_id, 0) + quantity
	
	# Recalculate harga setelah penjualan
	var new_price = _calculate_and_store_price(item_id)
	
	# Emit signals
	emit_signal("item_sold", item_id, quantity, total_price)
	emit_signal("price_updated", item_id, new_price)
	
	print("💰 Sold %d x %s @ %.2f each = %.2f total" % [quantity, item_id, price_per_unit, total_price])
	print("   New price: %.2f (was %.2f)" % [new_price, price_per_unit])
	
	return true


# ============================================================================
# UTILITY & DEBUG
# ============================================================================
func get_purchase_count(item_id: String) -> int:
	return _purchase_history.get(item_id, 0)


func get_sell_count(item_id: String) -> int:
	return _sell_history.get(item_id, 0)

	#Reset riwayat pembelian/penjualan.
	#Jika item_id kosong, reset semua.
func reset_history(item_id: String = "") -> void:
	if item_id.is_empty():
		for key in _purchase_history.keys():
			_purchase_history[key] = 0
			_sell_history[key] = 0
			_calculate_and_store_price(key)
		print("✓ Reset all purchase/sell history")
	else:
		_purchase_history[item_id] = 0
		_sell_history[item_id] = 0
		_calculate_and_store_price(item_id)
		print("✓ Reset history for item: %s" % item_id)


func get_item_count() -> int:
	return _registered_items.size()


func _initialize_prices() -> void:
	for item_id in _registered_items.keys():
		_calculate_and_store_price(item_id)
