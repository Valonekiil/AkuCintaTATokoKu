# Sistem Inventori — TokoDinamis

Dokumentasi ringkas sistem inventori pemain pada proyek **TokoDinamis** (Godot 4.5, GDScript).
Sistem ini dibangun di atas resource item dari plugin **DynamicShop** (`addons/Waijo/`).

---

## 1. Arsitektur Ringkas

```
CharacterBody2D
├── InventoryManager  (Script/InventoryManager.gd)   ← "otak" inventori
├── CanvasLayer  (inventory UI, visible = false)
│   └── Control
│       ├── ColorRect          ← overlay gelap saat inventori terbuka
│       ├── Label "INVENTORY"  ← judul
│       ├── Marc (MarginContainer)
│       │   └── GridContainer2 (InventoryContainer)  ← kumpulan slot
│       └── Panel (InventoryPanel)                   ← panel detail item (tooltip)
└── ... (player, kamera, dll)
```

Alur data: **Item (Resource `DynamicShopItem`) → Slot (Grid) → Panel detail (saat hover)**.

| Komponen | File | Peran |
|---|---|---|
| `InventoryManager` | `Script/InventoryManager.gd` | Menginisialisasi grid, mengontrol panel detail, status `holding` |
| `InventoryContainer` | `Script/InventoryContainer.gd` | `extends GridContainer`; membuat slot, mengisi item, mengikuti kursor |
| `InventorySlot` | `Script/InventorySlot.gd` + `InventorySlot.tscn` | Satu sel inventori; mendeteksi hover |
| `InventoryPanel` | `Script/InventoryPanelgd.gd` + `InventoryPanel.tscn` | Panel detail item yang mengikuti kursor |
| `DynamicShopItem` | `addons/Waijo/data/dynamic_shop_item.gd` | Resource data item (nama, harga, ikon, kategori, deskripsi) |

---

## 2. Konfigurasi di Main_World.tscn

`InventoryManager` di-instance sebagai child `CharacterBody2D` dengan export yang diisi:

```
Inventory_Size    = 100
Inventory         = ../CanvasLayer/Control/Marc/GridContainer2   (InventoryContainer)
Inventory_Items   = [Borgar, Health Potion, Choco Ball, King Fries, RedFin]
Inventory_Panel   = ../CanvasLayer/Control/Panel                 (InventoryPanel)
```

> Catatan: `Inventory_Items` adalah `Array[DynamicShopItem]` — item awal yang langsung
> ditampilkan mengisi slot pertama. Sisa slot dibuat kosong.

---

## 3. Alur Kerja (Step-by-step)

### 3.1 Inisialisasi — `InventoryManager._ready()`
1. Menautkan `Inventory.Inventory_Manager = self` (referensi balik ke manager).
2. Memanggil `Inventory.make_inventory(Inventory_Size)` untuk membuat grid slot.
3. Menyembunyikan `Inventory_Panel` dan mengatur `holding = false`.

### 3.2 Membuat grid — `InventoryContainer.make_inventory(size)`
1. Mengulang `size` kali, menginstantiate `InventorySlot.tscn` per iterasi.
2. Menamai tiap slot `Slot<i>` dan menambahkannya sebagai child Grid.
3. Menghubungkan sinyal slot ke manager:
   - `slot.show_item` → `Inventory_Manager.show_item_holded`
   - `slot.hide_item` → `Inventory_Manager.hide_item_holded`
4. Jika slot punya `count`, tampilkan teks jumlah; jika tidak, sembunyikan.
5. Mengisi item awal dari `Inventory_Manager.Inventory_Items` ke slot-slot pertama
   (`slot.holded_item = item`, `slot.img.texture = item.icon`).

### 3.3 Interaksi hover — `InventorySlot`
- **Mouse masuk** (`_on_mouse_entered`): jika slot berisi item, emit `show_item(item)`.
- **Mouse keluar** (`_on_mouse_exited`): emit `hide_item`.
- `_enter_tree()` mengambil referensi node UI (`TextureRect` = `img`, `Label` = `count_text`).

### 3.4 Menampilkan detail — `InventoryManager.show_item_holded(item)`
Mengisi `InventoryPanel` lalu menampilkannya:
- `item_name.text`  ← `item.display_name`
- `img.texture`     ← `item.icon`
- `worth.text`      ← `item.base_price`
- `category.text`   ← `item.category.name`
- `desc.text`       ← `item.description`
- set `holding = true`

### 3.5 Panel mengikuti kursor — `InventoryContainer._physics_process()`
Selama `Inventory_Manager.holding == true`, posisi `Inventory_Panel` di-set ke
posisi kursor global, sehingga panel detail "menempel" pada mouse.

### 3.6 Menyembunyikan — `InventoryManager.hide_item_holded()`
Menyembunyikan `Inventory_Panel` dan mengatur `holding = false`.

---

## 4. File Resource Item (`DynamicShopItem`)

Field yang dipakai sistem inventori (dari `addons/Waijo/data/dynamic_shop_item.gd`):

| Field | Tipe | Dipakai untuk |
|---|---|---|
| `item_name` | `String` | Nama utama item (plugin) |
| `display_name` | `String` | Nama tampilan di panel inventori |
| `base_price` | `float` | Harga dasar (ditampilkan di panel) |
| `current_price` | `float` | Harga terkini (dipakai shop) |
| `category` | `ShopCategory` | Kategori; `.name` sering dipakai |
| `icon` | `Texture2D` | Ikon di slot & panel |
| `description` | `String` | Deskripsi di panel |

---

## 5. Catatan / Keterbatasan Saat Ini

- **Belum ada logika stok/kuantitas dinamis** — `count` di slot adalah nilai statis
  dari scene `InventorySlot.tscn` (teks default "999").
- **Belum ada drag & drop / tukar slot** — interaksi hanya hover untuk menampilkan detail.
- **Panel detail tidak terkunci** — mengikuti kursor selama `holding`.
- **Item awal hardcoded** di inspector `Main_World.tscn` (`Inventory_Items`).
- Sistem inventori **terpisah** dari sistem transaksi shop (plugin DynamicShop) —
  belum ada sinkronisasi "beli item → masuk ke inventori".

---

## 6. Cara Menjalankan

1. Buka proyek dengan Godot 4.5.
2. Jalankan scene utama: `res://Main_World.tscn`.
3. Tekan **Tab** di dekat shop untuk membuka UI shop (plugin DynamicShop).
4. Inventori pemain berada di bawah `CharacterBody2D/CanvasLayer`.
5. Hover di atas slot untuk melihat panel detail item.
