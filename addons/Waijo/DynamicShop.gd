class_name DynamicShop
extends Node

# ============================================================================
# SIGNAL (Event-Driven Architecture - Bab 3.2.2.B)
# ============================================================================
signal item_purchased(item_id: String, quantity: int, final_price: float, remaining_stock: int)
signal item_sold(item_id: String, quantity: int, final_price: float, remaining_stock: int)
signal price_updated(item_id: String, new_price: float, stock_changed: bool)
signal stock_updated(item_id: String, new_stock: int, is_out_of_stock: bool)
signal shop_initialized(shop_name: String, item_count: int)
signal stock_about_to_deplete(item_id: String, current_stock: int, threshold: int)

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

# ⭐ FITUR BARU: Stock-aware pricing config
@export var default_stock_sensitivity: float = 0.5
@export var auto_restock_enabled: bool = true
@export var restock_interval: float = 60.0  # Detik antara restock (default 1 menit)

# ============================================================================
# DATA RUNTIME (Tidak Diekspor)
# ============================================================================
var _registered_items: Dictionary = {}  # {item_id: DynamicShopItem}
var _purchase_history: Dictionary = {}  # {item_id: purchase_count}
var _sell_history: Dictionary = {}      # {item_id: sell_count}
var _current_prices: Dictionary = {}    # {item_id: current_price}
var _stock_history: Dictionary = {}     # {item_id: Array[int]} untuk sparkline stok (max 10 points)
var _restock_timer: float = 0.0
var _low_stock_threshold: int = 2  # Threshold untuk signal stock_about_to_deplete

# ============================================================================
# LIFECYCLE
# ============================================================================
func _ready() -> void:
	_register_all_items()
	_initialize_prices()
	_initialize_stock_history()
	emit_signal("shop_initialized", shop_name, _registered_items.size())
	print("✓ Shop '%s' initialized with %d items" % [shop_name, _registered_items.size()])


func _process(delta: float) -> void:
	# Auto-restock logic (jika enabled)
	if auto_restock_enabled:
		_restock_timer += delta
		if _restock_timer >= restock_interval:
			_restock_items(delta)
			_restock_timer = 0.0


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
			# Inisialisasi stok default jika belum diset
			if item.max_stock <= 0:
				item.max_stock = 999
			if item.current_stock > item.max_stock:
				item.current_stock = item.max_stock


func _initialize_stock_history() -> void:
	# Initialize circular buffer untuk stock history (max 10 points)
	for item_id in _registered_items.keys():
		_stock_history[item_id] = []


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
	_stock_history[item.item_id] = []
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
# FUNGSI INTEGRASI: HARGA FINAL (Dengan Stock-Aware Pricing - Bab 2.2.2 Extension)
# ============================================================================
	#Menghitung harga final dan menyimpannya ke _current_prices.
	#Rumus baru: final_price = baseline × (1 + demand_impact - sell_impact) × stock_multiplier
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
	
	# ⭐ FITUR BARU: Stock multiplier (Bab 2.2.2 Extension)
	# Rumus: stock_multiplier = 1.0 + (stock_sensitivity × (1 - current_stock / max_stock))
	var stock_multiplier = _calculate_stock_multiplier(item)
	
	# Harga final dengan stock multiplier
	var final_price = clamp(baseline * price_multiplier * stock_multiplier, baseline * 0.3, baseline * 3.0)
	_current_prices[item_id] = final_price
	
	return final_price


# ============================================================================
# ALGORITMA 3: STOCK MULTIPLIER (Bab 2.2.2 Extension)
# ============================================================================
	#Menghitung multiplier harga berdasarkan stok tersedia.
	#Rumus: stock_multiplier = 1.0 + (stock_sensitivity × (1 - current_stock / max_stock))
	#
	#Dimana:
	#- stock_sensitivity = 0.5 (default, bisa di-config per item)
	#- Jika stok menipis (<20%): multiplier > 1.0 → harga naik
	#- Jika stok penuh (>80%): multiplier < 1.0 → harga turun
	#- Jika stok = 0: return INF (item tidak bisa dibeli)
func _calculate_stock_multiplier(item: DynamicShopItem) -> float:
	if item.current_stock <= 0:
		return INF  # Out of stock = tidak bisa dibeli
	
	if item.max_stock <= 0:
		return 1.0  # Edge case: max_stock invalid
	
	var stock_ratio = float(item.current_stock) / float(item.max_stock)
	var sensitivity = item.stock_sensitivity if item.stock_sensitivity > 0 else default_stock_sensitivity
	
	# stock_multiplier = 1.0 + (sensitivity × (1 - stock_ratio))
	# Contoh: stock_ratio=0.1 (10%), sensitivity=0.5 → multiplier = 1.0 + (0.5 × 0.9) = 1.45
	var stock_multiplier = 1.0 + (sensitivity * (1.0 - stock_ratio))
	
	return stock_multiplier

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
# TRANSAKSI: BELI & JUAL (Dengan Stock Tracking - Bab 3.2.2)
# ============================================================================
	#Pemain membeli item dari toko.
	#- Kurangi current_stock
	#- Harga naik berdasarkan demand_impact + stock_multiplier
	#- Emit signal untuk UI update dengan remaining_stock
func purchase_item(item_id: String, quantity: int = 1) -> bool:
	var item = _registered_items.get(item_id)
	if item == null:
		push_error("Purchase failed: Item '%s' not found" % item_id)
		return false
	
	if quantity <= 0:
		push_error("Purchase failed: Quantity must be > 0")
		return false
	
	# ⭐ FITUR BARU: Cek stok tersedia
	if item.current_stock <= 0:
		push_warning("Purchase failed: Item '%s' is out of stock" % item_id)
		return false
	
	# Handle batch purchase: beli sebanyak yang tersedia jika quantity > current_stock
	var actual_quantity = min(quantity, item.current_stock)
	var partial_success = quantity > actual_quantity
	
	# Hitung harga sebelum update stock
	var price_per_unit = get_current_price(item_id)
	var total_price = price_per_unit * actual_quantity
	
	# Update stock
	item.current_stock -= actual_quantity
	_update_stock_history(item_id, item.current_stock)
	
	# Emit stock_updated signal
	var is_out_of_stock = item.current_stock <= 0
	emit_signal("stock_updated", item_id, item.current_stock, is_out_of_stock)
	
	# Check low stock threshold
	if item.current_stock > 0 and item.current_stock <= _low_stock_threshold:
		emit_signal("stock_about_to_deplete", item_id, item.current_stock, _low_stock_threshold)
	
	# Update history pembelian
	_purchase_history[item_id] = _purchase_history.get(item_id, 0) + actual_quantity
	
	# Recalculate harga setelah pembelian (harga akan naik karena stock berkurang)
	var new_price = _calculate_and_store_price(item_id)
	
	# Emit signals
	emit_signal("item_purchased", item_id, actual_quantity, total_price, item.current_stock)
	emit_signal("price_updated", item_id, new_price, true)
	
	print("🛒 Purchased %d x %s @ %.2f each = %.2f total" % [actual_quantity, item_id, price_per_unit, total_price])
	print("   Stock: %d/%d → %d" % [item.current_stock + actual_quantity, item.max_stock, item.current_stock])
	print("   New price: %.2f (was %.2f)" % [new_price, price_per_unit])
	
	if partial_success:
		print("⚠️ Partial success: requested %d, but only %d available" % [quantity, actual_quantity])
	
	return true


	#Pemain menjual item ke toko.
	#- Tambah current_stock
	#- Harga turun berdasarkan sell_impact + stock_multiplier
	#- Emit signal untuk UI update dengan remaining_stock
func sell_item(item_id: String, quantity: int = 1) -> bool:
	var item = _registered_items.get(item_id)
	if item == null:
		push_error("Sell failed: Item '%s' not found" % item_id)
		return false
	
	if quantity <= 0:
		push_error("Sell failed: Quantity must be > 0")
		return false
	
	# Hitung harga sebelum update stock
	var price_per_unit = get_current_price(item_id)
	var total_price = price_per_unit * quantity
	
	# Update stock (tambah)
	item.current_stock += quantity
	
	# Clamp stock to max_stock (optional: bisa di-disable jika ingin overstock)
	if item.current_stock > item.max_stock:
		print("⚠️ Warning: Item '%s' is overstocked (%d/%d)" % [item_id, item.current_stock, item.max_stock])
	
	_update_stock_history(item_id, item.current_stock)
	
	# Emit stock_updated signal
	var is_out_of_stock = item.current_stock <= 0
	emit_signal("stock_updated", item_id, item.current_stock, is_out_of_stock)
	
	# Update history penjualan
	_sell_history[item_id] = _sell_history.get(item_id, 0) + quantity
	
	# Recalculate harga setelah penjualan (harga akan turun karena stock bertambah)
	var new_price = _calculate_and_store_price(item_id)
	
	# Emit signals
	emit_signal("item_sold", item_id, quantity, total_price, item.current_stock)
	emit_signal("price_updated", item_id, new_price, true)
	
	print("💰 Sold %d x %s @ %.2f each = %.2f total" % [quantity, item_id, price_per_unit, total_price])
	print("   Stock: %d/%d → %d" % [item.current_stock - quantity, item.max_stock, item.current_stock])
	print("   New price: %.2f (was %.2f)" % [new_price, price_per_unit])
	
	return true


# ============================================================================
# UTILITY & DEBUG
# ============================================================================
func get_purchase_count(item_id: String) -> int:
	return _purchase_history.get(item_id, 0)


func get_sell_count(item_id: String) -> int:
	return _sell_history.get(item_id, 0)


func get_current_stock(item_id: String) -> int:
	var item = _registered_items.get(item_id)
	if item:
		return item.current_stock
	return 0


func get_max_stock(item_id: String) -> int:
	var item = _registered_items.get(item_id)
	if item:
		return item.max_stock
	return 0


func get_stock_percentage(item_id: String) -> float:
	var item = _registered_items.get(item_id)
	if item and item.max_stock > 0:
		return float(item.current_stock) / float(item.max_stock)
	return 1.0


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


# ============================================================================
# STOCK HISTORY (Circular Buffer untuk Sparkline - Max 10 Points)
# ============================================================================
func _update_stock_history(item_id: String, new_stock: int) -> void:
	if not _stock_history.has(item_id):
		_stock_history[item_id] = []
	
	var history: Array = _stock_history[item_id]
	history.append(new_stock)
	
	# Circular buffer: max 10 points
	if history.size() > 10:
		history.pop_front()


func get_stock_history(item_id: String) -> Array:
	if _stock_history.has(item_id):
		return _stock_history[item_id]
	return []


# ============================================================================
# AUTO-RESTOCK SYSTEM (Bab 3.2.2 Extension)
# ============================================================================
	#Auto-restock logic: tambah stok secara berkala berdasarkan restock_rate.
	#Rumus: restock_amount = floor(max_stock × restock_rate × delta_minutes)
	#
	#Dimana:
	#- restock_rate = % restock per menit (config per item)
	#- delta_minutes = waktu sejak restock terakhir (dalam menit)
func _restock_items(delta: float) -> void:
	var delta_minutes = delta / 60.0
	var restocked_count = 0
	
	for item_id in _registered_items.keys():
		var item: DynamicShopItem = _registered_items[item_id]
		
		# Hanya restock item yang memiliki restock_rate > 0
		if item.restock_rate <= 0:
			continue
		
		# Skip jika sudah full stock
		if item.current_stock >= item.max_stock:
			continue
		
		# Hitung amount to restock
		var restock_amount = int(floor(float(item.max_stock) * item.restock_rate * delta_minutes))
		restock_amount = max(1, restock_amount)  # Minimal 1 unit
		
		# Apply restock (tidak melebihi max_stock)
		var old_stock = item.current_stock
		item.current_stock = min(item.current_stock + restock_amount, item.max_stock)
		var actual_restocked = item.current_stock - old_stock
		
		if actual_restocked > 0:
			restocked_count += 1
			_update_stock_history(item_id, item.current_stock)
			
			# Recalculate price (harga turun karena supply naik)
			var new_price = _calculate_and_store_price(item_id)
			
			# Emit signals
			emit_signal("stock_updated", item_id, item.current_stock, false)
			emit_signal("price_updated", item_id, new_price, true)
			
			print("✨ Restocked %d x %s (%d → %d/%d)" % [actual_restocked, item_id, old_stock, item.current_stock, item.max_stock])
	
	if restocked_count > 0:
		print("✓ Auto-restock completed: %d items restocked" % restocked_count)


	#Manual restock untuk item tertentu (bisa dipanggil dari UI/debug)
func manual_restock(item_id: String, amount: int = -1) -> bool:
	var item = _registered_items.get(item_id)
	if item == null:
		return false
	
	if amount < 0:
		# Full restock
		item.current_stock = item.max_stock
	else:
		item.current_stock = min(item.current_stock + amount, item.max_stock)
	
	_update_stock_history(item_id, item.current_stock)
	var new_price = _calculate_and_store_price(item_id)
	
	emit_signal("stock_updated", item_id, item.current_stock, false)
	emit_signal("price_updated", item_id, new_price, true)
	
	print("🔧 Manual restock: %s → %d/%d" % [item_id, item.current_stock, item.max_stock])
	return true
