extends Panel
class_name InventorySlot

signal show_item(item:DynamicShopItem)
signal hide_item

var holded_item:DynamicShopItem
var count:int
var img: TextureRect 
var count_text: Label 
var cur_panel:InventoryPanel

func _enter_tree() -> void:
	img = find_child("TextureRect")
	count_text = find_child("Label")

func _on_mouse_entered() -> void:
	if holded_item:
		show_item.emit(holded_item)

func _on_mouse_exited() -> void:
	hide_item.emit()
