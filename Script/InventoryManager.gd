extends Node
class_name InventoryManager

@export var Inventory_Size:int
@export var Inventory:InventoryContainer
@export var Inventory_Items:Array[DynamicShopItem]
@export var Inventory_Panel:InventoryPanel
var holding:bool

# ⭐ FITUR BARU: Shop reference untuk sync
var _linked_shop: DynamicShop = null

func _ready() -> void:
	Inventory.Inventory_Manager = self
	Inventory.make_inventory(Inventory_Size)
	Inventory_Panel.visible = false
	holding = false

func show_item_holded(item:DynamicShopItem):
	Inventory_Panel.visible = true
	Inventory_Panel.item_name.text = item.display_name
	Inventory_Panel.img.texture = item.icon
	Inventory_Panel.worth.text = str(item.base_worth)
	Inventory_Panel.category.text = item.category
	Inventory_Panel.desc.text = item.description
	holding = true
	print("show")

func hide_item_holded():
	Inventory_Panel.visible = false
	holding = false
	print("hide")

# ============================================================================
# ⭐ FITUR BARU: INVENTORY ↔ SHOP SYNC SYSTEM
# ============================================================================

## Connect InventoryManager ke DynamicShop signals
func sync_with_shop(shop: DynamicShop) -> void:
	if shop == null:
		push_warning("Cannot sync with null shop")
		return
	
	_linked_shop = shop
	
	# Connect signals
	shop.item_purchased.connect(_on_shop_item_purchased)
	shop.item_sold.connect(_on_shop_item_sold)
	shop.stock_updated.connect(_on_shop_stock_updated)
	
	print("✓ InventoryManager synced with shop: %s" % shop.shop_name)


## Handler saat player beli dari shop → tambah ke inventory
func _on_shop_item_purchased(item_id: String, quantity: int, final_price: float, remaining_stock: int) -> void:
	var item = _find_item_by_id(item_id)
	if item == null:
		push_error("Cannot add to inventory: item '%s' not found" % item_id)
		return
	
	# Tambah item ke inventory (atau stack jika sudah ada)
	var added = add_to_inventory(item, quantity)
	if added:
		print("📦 Added %d x %s to inventory" % [quantity, item_id])
	else:
		push_warning("Failed to add %d x %s to inventory (full?)" % [quantity, item_id])


## Handler saat player sell ke shop → kurangi dari inventory
func _on_shop_item_sold(item_id: String, quantity: int, final_price: float, remaining_stock: int) -> void:
	# Kurangi item dari inventory
	var removed = remove_from_inventory(item_id, quantity)
	if removed:
		print("📤 Removed %d x %s from inventory" % [quantity, item_id])
	else:
		push_warning("Failed to remove %d x %s from inventory" % [quantity, item_id])


## Handler saat stock di shop update (untuk UI feedback)
func _on_shop_stock_updated(item_id: String, new_stock: int, is_out_of_stock: bool) -> void:
	# Optional: Update UI atau trigger efek visual
	if is_out_of_stock:
		print("⚠️ Shop item '%s' is now out of stock!" % item_id)
	else:
		print("📊 Shop item '%s' stock updated: %d" % [item_id, new_stock])


# ============================================================================
# HELPER: Cari item di inventory berdasarkan ID
# ============================================================================
func _find_item_by_id(item_id: String) -> DynamicShopItem:
	for item in Inventory_Items:
		if item and item.item_id == item_id:
			return item
	return null


# ============================================================================
# INVENTORY MANAGEMENT (Updated dengan validation)
# ============================================================================
func add_to_inventory(item: DynamicShopItem, quantity: int) -> bool:
	if item == null or quantity <= 0:
		return false
	
	# Cek apakah item sudah ada di inventory (stacking)
	for existing_item in Inventory_Items:
		if existing_item and existing_item.item_id == item.item_id:
			# Item sudah ada, bisa stack (optional logic)
			print("📚 Stacking %d x %s (existing item)" % [quantity, item.item_id])
			return true
	
	# Item baru, tambahkan ke array
	Inventory_Items.append(item)
	return true


func remove_from_inventory(item_id: String, quantity: int) -> bool:
	if item_id.is_empty() or quantity <= 0:
		return false
	
	# Cari dan hapus item dari inventory
	for i in range(Inventory_Items.size()):
		var item = Inventory_Items[i]
		if item and item.item_id == item_id:
			Inventory_Items.remove_at(i)
			return true
	
	return false


func get_item_count(item_id: String) -> int:
	var count = 0
	for item in Inventory_Items:
		if item and item.item_id == item_id:
			count += 1
	return count


func has_item(item_id: String) -> bool:
	return get_item_count(item_id) > 0


func clear_inventory() -> void:
	Inventory_Items.clear()
	print("🗑️ Inventory cleared")
