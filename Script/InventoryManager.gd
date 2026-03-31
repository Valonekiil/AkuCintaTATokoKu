extends Node
class_name InventoryManager

@export var Inventory_Size:int
@export var Inventory:InventoryContainer
@export var Inventory_Items:Array[DynamicShopItem]
@export var Inventory_Panel:InventoryPanel
var holding:bool

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
