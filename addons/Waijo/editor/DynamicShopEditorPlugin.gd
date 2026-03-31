@tool
extends EditorInspectorPlugin

func can_handle(object: Object) -> bool:
	# Handle DynamicShop nodes
	return object is DynamicShop


func parse_begin(object: Object) -> void:
	var shop = object as DynamicShop
	
	# Create custom UI container
	var container = VBoxContainer.new()
	container.name = "DynamicShopCustomUI"
	
	# Add shop info
	var info_label = Label.new()
	info_label.bbcode_enabled = true
	info_label.text = "[b][color=lightblue]🏪 %s[/color][/b]" % shop.shop_name
	info_label.add_theme_font_size_override("font_size", 16)
	container.add_child(info_label)
	
	# Add registered items list
	var items_label = Label.new()
	items_label.bbcode_enabled = true
	items_label.text = "[color=yellow]📋 Items Terdaftar:[/color]"
	container.add_child(items_label)
	
	# Add items list container
	var items_list = VBoxContainer.new()
	items_list.name = "ItemsList"
	items_list.custom_minimum_size = Vector2(0, 100)
	container.add_child(items_list)
	
	# Populate items list
	_populate_items_list(items_list, shop)
	
	# Add helper button
	var refresh_btn = Button.new()
	refresh_btn.text = "🔄 Refresh Items List"
	refresh_btn.connect("pressed", Callable(self, "_on_refresh_pressed").bind(items_list, shop))
	container.add_child(refresh_btn)
	
	# Add to inspector
	add_custom_control(container)


func _populate_items_list(container: VBoxContainer, shop: DynamicShop) -> void:
	# Clear existing children
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	
	# Get registered items
	var items = []
	if shop.has_method("get_all_registered_items"):
		items = shop.get_all_registered_items()
	
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "[i]Belum ada item terdaftar[/i]"
		empty_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		container.add_child(empty_label)
		return
	
	# Add each item
	for item in items:
		var item_label = Label.new()
		item_label.bbcode_enabled = true
		var baseline = item.base_worth * item.item_scale
		item_label.text = "• [b]%s[/b] ([color=gray]%s[/color]) - Baseline: [color=yellow]%.2f[/color] | Elasticity: [color=%s]%.2f[/color]" % [
			item.display_name,
			item.item_id,
			baseline,
			"lightgreen" if item.price_elasticity < 1.0 else "lightblue",
			item.price_elasticity
		]
		container.add_child(item_label)


func _on_refresh_pressed(container: VBoxContainer, shop: DynamicShop) -> void:
	_populate_items_list(container, shop)
