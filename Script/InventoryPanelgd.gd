extends Panel
class_name InventoryPanel

@onready var item_name: Label = $Name
@onready var img: TextureRect = $img
@onready var worth: Label = $VBoxContainer/WorthCont/Label
@onready var category: Label = $VBoxContainer/Category/Label
@onready var desc: Label = $VBoxContainer/Desc
