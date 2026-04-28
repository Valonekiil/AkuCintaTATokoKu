@tool
extends EditorPlugin

const PRICING_ENGINE_PATH = "res://addons/Waijo/PriceManager.gd"
const PRICING_ENGINE_NAME = "PriceManager"


func _enter_tree() -> void:
	# Auto-register PricingEngine sebagai autoload saat plugin aktif
	add_autoload_singleton(PRICING_ENGINE_NAME, PRICING_ENGINE_PATH)
	
	print("✓ Waijo Dynamic Shop Plugin loaded!")
	print("  - PricingEngine registered as autoload")
	print("  - Access via: PriceManager (global)")


func _exit_tree() -> void:
	# Hapus autoload saat plugin dinonaktifkan
	remove_autoload_singleton(PRICING_ENGINE_NAME)
	
	print("✗ Waijo Dynamic Shop Plugin unloaded")
