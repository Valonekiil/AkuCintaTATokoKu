class_name PriceSparkline
extends Panel

## Reference ke Line2D untuk gambar grafik
@onready var line_2d: Line2D = $Line2D

## Buffer riwayat harga (max 10 points, circular buffer)
var price_history: Array[float] = []
var max_history_size: int = 10

## Warna garis berdasarkan trend
var color_rising: Color = Color(1.0, 0.4, 0.4, 1.0)   # Merah untuk harga naik
var color_falling: Color = Color(0.4, 1.0, 0.4, 1.0)  # Hijau untuk harga turun
var color_stable: Color = Color(1.0, 0.8, 0.2, 1.0)   # Emas untuk stabil


func _ready() -> void:
	line_2d.clear_points()


## Tambahkan harga baru ke history
func add_price(new_price: float) -> void:
	price_history.append(new_price)
	
	# Jaga max size (circular buffer)
	if price_history.size() > max_history_size:
		price_history.pop_front()
	
	# Redraw sparkline
	_draw_sparkline()
	
	# Update warna garis berdasarkan trend
	_update_trend_color()


## Gambar sparkline dari history harga
func _draw_sparkline() -> void:
	line_2d.clear_points()
	
	if price_history.size() < 2:
		return
	
	# Cari min/max untuk scaling vertikal
	var min_price = price_history.min()
	var max_price = price_history.max()
	var price_range = max_price - min_price
	
	# Kalau semua harga sama, kasih range kecil biar garis kelihatan
	if price_range < 0.01:
		price_range = 0.01
	
	# Generate points untuk Line2D
	var panel_size = size
	var step_x = panel_size.x / (max_history_size - 1) if max_history_size > 1 else panel_size.x
	
	for i in range(price_history.size()):
		var price = price_history[i]
		
		# Normalisasi harga ke posisi Y (0 = bottom, 1 = top)
		var normalized_y = (price - min_price) / price_range
		
		# Hitung posisi pixel
		var x = i * step_x
		var y = panel_size.y - (normalized_y * panel_size.y) - 5  # -5 untuk padding
		
		line_2d.add_point(Vector2(x, y))


## Update warna garis berdasarkan trend (harga terakhir vs pertama)
func _update_trend_color() -> void:
	if price_history.size() < 2:
		line_2d.default_color = color_stable
		return
	
	var first_price = price_history[0]
	var last_price = price_history[-1]
	var change_percent = (last_price - first_price) / first_price
	
	if change_percent > 0.01:  # Naik > 1%
		line_2d.default_color = color_rising
	elif change_percent < -0.01:  # Turun > 1%
		line_2d.default_color = color_falling
	else:  # Stabil (±1%)
		line_2d.default_color = color_stable


## Reset sparkline
func reset() -> void:
	price_history.clear()
	line_2d.clear_points()
	line_2d.default_color = color_stable
