extends Node

@onready var shop: DynamicShop = $Junkfood_Store


func _ready() -> void:
	# Connect signals
	shop.price_updated.connect(_on_price_updated)
	
	print("\n========================================")
	print("🧪 TESTING DYNAMIC PRICING ALGORITHM")
	print("========================================\n")
	
	# Test 1: Multiplicative Sampling
	#_test_multiplicative_sampling()
	
	# Test 2: Price Elasticity (Inelastis)
	#_test_price_elasticity_inelastic()
	
	# Test 3: Price Elasticity (Elastis)
	#_test_price_elasticity_elastic()
	
	# Test 4: Clamping
	#_test_price_clamping()


func _test_multiplicative_sampling() -> void:
	print("📊 TEST 1: Multiplicative Sampling")
	print("-----------------------------------")
	
	var item = shop.find_item_by_id("JUNK_001")
	if item:
		var baseline = shop._calculate_baseline_price(item)
		print("Item: %s" % item.display_name)
		print("  base_worth: %.2f" % item.base_worth)
		print("  item_scale: %.2f" % item.item_scale)
		print("  category: %s (scale: %.2f)" % [item.category, shop._get_category_scale(item.category)])
		print("  → Baseline Price: %.2f" % baseline)
		print("")


func _test_price_elasticity_inelastic() -> void:
	print("📈 TEST 2: Price Elasticity (Inelastis < 1.0)")
	print("----------------------------------------------")
	
	var item_id = "JUNK_001"
	var item = shop.find_item_by_id(item_id)
	if item:
		print("Item: %s (Elasticity: %.2f)" % [item.display_name, item.price_elasticity])
		print("  base_demand_impact: %.4f" % item.base_demand_impact)
		print("")
		
		# Simulasi 10 pembelian
		for i in range(1, 11):
			shop.purchase_item(item_id, 1)
			var price = shop.get_current_price(item_id)
			var count = shop.get_purchase_count(item_id)
			print("  Purchase #%d: Count=%d, Price=%.2f" % [i, count, price])
		
		print("")
		# Reset untuk test berikutnya
		shop.reset_history(item_id)


func _test_price_elasticity_elastic() -> void:
	print("📉 TEST 3: Price Elasticity (Elastis > 1.0)")
	print("--------------------------------------------")
	
	var item_id = "fish_salmon"
	var item = shop.find_item_by_id(item_id)
	if item:
		print("Item: %s (Elasticity: %.2f)" % [item.display_name, item.price_elasticity])
		print("  base_demand_impact: %.4f" % item.base_demand_impact)
		print("")
		
		# Simulasi 10 pembelian
		for i in range(1, 11):
			shop.purchase_item(item_id, 1)
			var price = shop.get_current_price(item_id)
			var count = shop.get_purchase_count(item_id)
			print("  Purchase #%d: Count=%d, Price=%.2f" % [i, count, price])
		
		print("")
		shop.reset_history(item_id)


func _test_price_clamping() -> void:
	print("🔒 TEST 4: Price Clamping (Min 30%, Max 300%)")
	print("-----------------------------------------------")
	
	var item_id = "JUNK_001"
	var item = shop.find_item_by_id(item_id)
	if item:
		var baseline = shop._calculate_baseline_price(item)
		print("Baseline: %.2f" % baseline)
		print("Min Price (30%%): %.2f" % (baseline * 0.3))
		print("Max Price (300%%): %.2f" % (baseline * 3.0))
		print("")
		
		# Beli banyak sampai hit clamp
		for i in range(1, 51):
			shop.purchase_item(item_id, 5)
		
		var final_price = shop.get_current_price(item_id)
		print("  After 50x5 purchases: Price=%.2f" % final_price)
		
		if final_price >= baseline * 3.0:
			print("  ✓ Clamping bekerja! Harga mentok di max (300%%)")
		else:
			print("  ⚠ Harga belum mencapai clamp max")
		
		print("")


func _on_price_updated(item_id: String, new_price: float) -> void:
	# Optional: Log setiap perubahan harga
	pass
