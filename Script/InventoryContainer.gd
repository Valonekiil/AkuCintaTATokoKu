extends GridContainer
class_name InventoryContainer

var Inventory_Manager:InventoryManager
var inventory_size:int 
const INVENTORY_SLOT = preload("res://InventorySlot.tscn")

func make_inventory(value:int) -> void:
	inventory_size = value
	for i in inventory_size:
		var slot:InventorySlot = INVENTORY_SLOT.instantiate()
		slot.name = "Slot" + str(i)
		add_child(slot)
		slot.show_item.connect(Inventory_Manager.show_item_holded)
		slot.hide_item.connect(Inventory_Manager.hide_item_holded)
		if !slot.count:
			slot.count_text.visible = false
		else:
			slot.count_text.text = str(slot.count)
	if Inventory_Manager:
		if !Inventory_Manager.Inventory_Items.is_empty():
			var count = 0
			for item in Inventory_Manager.Inventory_Items:
				var slot:InventorySlot = get_child(count)
				slot.holded_item = item
				slot.img.texture = item.icon
				count += 1

func _physics_process(delta: float) -> void:
	if Inventory_Manager.holding:
		Inventory_Manager.Inventory_Panel.global_position = get_global_mouse_position()
