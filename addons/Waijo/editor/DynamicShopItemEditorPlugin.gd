@tool
extends EditorInspectorPlugin

func can_handle(object: Object) -> bool:
	# Handle DynamicShopItem resources
	return object is DynamicShopItem


func parse_begin(object: Object) -> void:
	var item = object as DynamicShopItem
	
	# Create custom UI container
	var container = VBoxContainer.new()
	container.name = "DynamicShopItemCustomUI"
	
	# Add preview label
	var preview_label = Label.new()
	preview_label.bbcode_enabled = true
	preview_label.custom_minimum_size = Vector2(0, 40)
	preview_label.add_theme_font_size_override("font_size", 14)
	container.add_child(preview_label)
	
	# Update preview
	_update_preview(preview_label, item)
	
	# Add helper tips
	var tips_label = Label.new()
	tips_label.bbcode_enabled = true
	tips_label.text = "[color=yellow]💡 Tips:[/color]\n" + \
					 "• [b]Price Elasticity < 1.0[/b]: Barang inelastis (harga naik cepat, lalu melambat)\n" + \
					 "• [b]Price Elasticity > 1.0[/b]: Barang elastis (harga naik lambat, lalu cepat)\n" + \
                     "• [b]Base Demand Impact[/b]: Dampak per pembelian (0.001 = 0.1%)"
	tips_label.add_theme_font_size_override("font_size", 11)
	tips_label.custom_minimum_size = Vector2(0, 80)
	container.add_child(tips_label)
	
	# Add to inspector
	add_custom_control(container)
	
	# Connect signals for real-time update
	item.connect("property_list_changed", Callable(self, "_on_item_changed").bind(preview_label, item))


func _update_preview(label: Label, item: DynamicShopItem) -> void:
	var baseline_price = item.base_worth * item.item_scale
	
	label.text = "[b][color=lightgreen]📊 Preview Harga Baseline:[/color][/b]\n" + \
				 "Base Worth: [b]%s[/b] × Item Scale: [b]%s[/b] = [color=yellow][b]%.2f[/b][/color]" % [
					 item.base_worth,
					 item.item_scale,
					 baseline_price
				 ]


func _on_item_changed(label: Label, item: DynamicShopItem) -> void:
	_update_preview(label, item)
