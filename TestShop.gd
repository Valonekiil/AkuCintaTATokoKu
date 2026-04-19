class_name TestShopController
extends Node

@onready var shop: DynamicShop = $Junkfood_Store
@onready var shop_display: ShopDisplay = $CanvasLayer/PanelRoot

## UI References (untuk test manual)
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var gold_label: Label = $CanvasLayer/GoldLabel

var player_gold: int = 1000


func _ready() -> void:
	# Connect signals untuk logging
	shop.item_purchased.connect(_on_purchase_completed)
	shop.item_sold.connect(_on_sell_completed)
	
	_update_gold_display()
	
	print("\n========================================")
	print("🎮 TEST SHOP SCENE READY")
	print("========================================")
	print("Player Gold: %d" % player_gold)
	print("Instructions:")
	print("  - Click item di UI untuk beli (auto 1x)")
	print("  - Tekan 'S' untuk sell item test")
	print("  - Tekan 'R' untuk reset history")
	print("  - Tekan '1' untuk Test Scenario 1: Stock Depletion → Price Spike")
	print("  - Tekan '2' untuk Test Scenario 2: Batch Purchase Edge Case")
	print("  - Tekan '3' untuk Test Scenario 3: Auto-Restock Test (simulasi)")
	print("  - Tekan '4' untuk Test Scenario 4: Memory & Performance Test")
	print("========================================\n")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_S:
			_test_sell()
		elif event.keycode == KEY_R:
			_test_reset()
		elif event.keycode == KEY_1:
			_test_buy_until_out_of_stock()
		elif event.keycode == KEY_2:
			_test_batch_purchase()
		elif event.keycode == KEY_3:
			_test_restock_timer()
		elif event.keycode == KEY_4:
			_test_performance()

func _on_purchase_completed(item_id: String, quantity: int, final_price: float, remaining_stock: int) -> void:
	var total = final_price * quantity
	if player_gold >= total:
		player_gold -= int(total)
		_update_gold_display()
		status_label.text = "🛒 Bought %d x %s (%.0f gold) - Stock: %d" % [quantity, item_id, total, remaining_stock]
	else:
		status_label.text = "❌ Not enough gold!"


func _on_sell_completed(item_id: String, quantity: int, final_price: float, remaining_stock: int) -> void:
	var total = final_price * quantity
	player_gold += int(total)
	_update_gold_display()
	status_label.text = "💰 Sold %d x %s (%.0f gold) - Stock: %d" % [quantity, item_id, total, remaining_stock]


func _test_sell() -> void:
	# Test sell function (untuk demo harga turun)
	var items = shop.get_all_registered_items()
	if items.size() > 0:
		var item = items[0]
		shop.sell_item(item.item_id, 1)


func _test_reset() -> void:
	shop.reset_history()
	status_label.text = "🔄 History reset!"
	print("✓ Reset all purchase/sell history")


func _update_gold_display() -> void:
	gold_label.text = "💰 Gold: %d" % player_gold


# ============================================================================
# ⭐ TEST SCENARIOS (Dari Prompt)
# ============================================================================

## Scenario 1: Stock Depletion → Price Spike
func _test_buy_until_out_of_stock() -> void:
	print("\n========================================")
	print("🧪 TEST SCENARIO 1: Stock Depletion → Price Spike")
	print("========================================")
	
	var items = shop.get_all_registered_items()
	if items.size() == 0:
		print("❌ No items available for testing")
		return
	
	# Pilih item dengan stok terbatas untuk demo
	var test_item = items[0]
	var original_stock = test_item.current_stock
	var original_price = shop.get_current_price(test_item.item_id)
	
	print("📦 Item: %s" % test_item.display_name)
	print("   Original Stock: %d/%d" % [original_stock, test_item.max_stock])
	print("   Original Price: %.2f GOLD" % original_price)
	
	# Beli sampai stok < 20%
	var target_stock = int(test_item.max_stock * 0.2)
	var purchases_needed = original_stock - target_stock
	
	print("\n🛒 Buying %d units to deplete stock to 20%..." % purchases_needed)
	
	for i in range(purchases_needed):
		if test_item.current_stock <= 0:
			break
		shop.purchase_item(test_item.item_id, 1)
	
	var price_at_low_stock = shop.get_current_price(test_item.item_id)
	print("\n📊 After buying %d units:" % purchases_needed)
	print("   Current Stock: %d/%d (%.1f%%)" % [test_item.current_stock, test_item.max_stock, shop.get_stock_percentage(test_item.item_id) * 100])
	print("   Current Price: %.2f GOLD (%+.1f%% from original)" % [price_at_low_stock, ((price_at_low_stock - original_price) / original_price) * 100])
	
	# Beli sampai habis
	print("\n🛒 Buying remaining stock...")
	while test_item.current_stock > 0:
		shop.purchase_item(test_item.item_id, 1)
	
	var final_price = shop.get_current_price(test_item.item_id)
	print("\n✅ OUT OF STOCK!")
	print("   Final Stock: %d/%d" % [test_item.current_stock, test_item.max_stock])
	print("   Final Price: %.2f GOLD" % final_price)
	print("========================================\n")


## Scenario 2: Batch Purchase Edge Cases
func _test_batch_purchase() -> void:
	print("\n========================================")
	print("🧪 TEST SCENARIO 2: Batch Purchase Edge Cases")
	print("========================================")
	
	var items = shop.get_all_registered_items()
	if items.size() == 0:
		print("❌ No items available for testing")
		return
	
	var test_item = items[0]
	
	# Restock dulu untuk testing
	test_item.current_stock = test_item.max_stock
	var available_stock = test_item.current_stock
	
	print("📦 Item: %s" % test_item.display_name)
	print("   Available Stock: %d" % available_stock)
	
	# Coba beli lebih dari stok tersedia
	var requested_quantity = available_stock + 5
	print("\n🛒 Attempting to buy %d (but only %d available)..." % [requested_quantity, available_stock])
	
	var success = shop.purchase_item(test_item.item_id, requested_quantity)
	
	print("\n📊 Result:")
	print("   Success: %s" % ("✅ Yes (partial)" if success else "❌ No"))
	print("   Remaining Stock: %d" % test_item.current_stock)
	print("   Expected: Should be 0 (bought all available)")
	print("========================================\n")


## Scenario 3: Auto-Restock Timer (Simulasi)
func _test_restock_timer() -> void:
	print("\n========================================")
	print("🧪 TEST SCENARIO 3: Auto-Restock Simulation")
	print("========================================")
	
	var items = shop.get_all_registered_items()
	if items.size() == 0:
		print("❌ No items available for testing")
		return
	
	# Cari item dengan restock_rate > 0
	var test_item: DynamicShopItem = null
	for item in items:
		if item.restock_rate > 0:
			test_item = item
			break
	
	if test_item == null:
		print("⚠️ No item with restock_rate > 0 found. Using first item with simulated restock.")
		test_item = items[0]
		test_item.restock_rate = 0.1  # 10% per menit
	
	# Deplete stock dulu
	test_item.current_stock = int(test_item.max_stock * 0.1)  # 10% stock
	print("📦 Item: %s" % test_item.display_name)
	print("   Initial Stock: %d/%d (%.1f%%)" % [test_item.current_stock, test_item.max_stock, shop.get_stock_percentage(test_item.item_id) * 100])
	print("   Restock Rate: %.1f%% per minute" % (test_item.restock_rate * 100))
	
	# Simulasi restock manual (karena tidak bisa tunggu real-time)
	print("\n⏳ Simulating 5 minutes of restock...")
	var delta_minutes = 5.0
	var restock_amount = int(floor(float(test_item.max_stock) * test_item.restock_rate * delta_minutes))
	restock_amount = max(1, restock_amount)
	
	var old_stock = test_item.current_stock
	test_item.current_stock = min(test_item.current_stock + restock_amount, test_item.max_stock)
	var actual_restocked = test_item.current_stock - old_stock
	
	print("\n✨ Restocked %d units" % actual_restocked)
	print("   New Stock: %d/%d (%.1f%%)" % [test_item.current_stock, test_item.max_stock, shop.get_stock_percentage(test_item.item_id) * 100])
	
	# Recalculate price
	var new_price = shop.get_current_price(test_item.item_id)
	print("   New Price: %.2f GOLD (should be lower due to increased supply)" % new_price)
	print("========================================\n")


## Scenario 4: Memory & Performance Test
func _test_performance() -> void:
	print("\n========================================")
	print("🧪 TEST SCENARIO 4: Memory & Performance Test")
	print("========================================")
	
	var items = shop.get_all_registered_items()
	if items.size() == 0:
		print("❌ No items available for testing")
		return
	
	var test_item = items[0]
	var transactions = 100
	var start_time = Time.get_ticks_ms()
	
	print("⚡ Running %d transactions..." % transactions)
	
	# Reset stock untuk testing
	test_item.current_stock = 999
	
	for i in range(transactions):
		if i % 2 == 0:
			shop.purchase_item(test_item.item_id, 1)
		else:
			shop.sell_item(test_item.item_id, 1)
	
	var end_time = Time.get_ticks_ms()
	var elapsed_ms = end_time - start_time
	
	print("\n📊 Results:")
	print("   Total Transactions: %d" % transactions)
	print("   Time Elapsed: %d ms (%.2f sec)" % [elapsed_ms, float(elapsed_ms) / 1000.0])
	print("   Transactions/sec: %.1f" % (float(transactions) / (float(elapsed_ms) / 1000.0)))
	print("   FPS Impact: Should be minimal (no rendering in this test)")
	print("========================================\n")
