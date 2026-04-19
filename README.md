# Test TA - Dynamic Shop System

A Godot 4.x project implementing a dynamic shop/trading system with price elasticity, inventory management, and visual price history tracking.

## Project Overview

This project demonstrates a complete shop system with:
- **Dynamic Pricing**: Prices change based on purchase/sell history using elasticity calculations
- **Inventory Management**: Track player items and gold
- **Visual Price History**: Sparkline graphs showing price trends over time
- **Interactive UI**: Click-to-buy interface with tooltips and hover effects

## Requirements

- **Godot Engine**: 4.5+ (Forward Plus renderer)
- **Resolution**: 640x360 viewport (scalable)

## Project Structure

```
├── Script/                 # GDScript files
│   ├── InventoryManager.gd      # Core inventory logic
│   ├── InventoryContainer.gd    # Inventory container handling
│   ├── InventoryPanelgd.gd      # UI panel for inventory
│   ├── InventorySlot.gd         # Individual slot behavior
│   ├── ShopPanel.gd             # Shop item display panel
│   ├── ShopDisplay.gd           # Main shop display controller
│   ├── PriceHistorySparkline.gd # Visual price trend graph
│   ├── ItemSpawner.gd           # Item spawning utility
│   └── testshop.gd              # Test controller script
├── asset/                  # Game assets
│   ├── *.png               # Item icons (food, fish, potions, etc.)
│   └── resource_dynamic/   # Dynamic resources
├── addons/                 # Editor plugins
│   └── Waijo/              # TokoKuBetterThanMeduro plugin
├── *.tscn                  # Scene files
│   ├── Main_World.tscn     # Main game scene
│   ├── TestShop.gd         # Test shop scene
│   ├── ShopDisplay.tscn    # Shop display UI
│   ├── InventoryPanel.tscn # Inventory UI
│   └── ...
└── project.godot           # Project configuration
```

## Features

### Dynamic Shop System
- Items with configurable base prices and elasticity values
- Multiplicative sampling for price calculation
- Purchase history tracking affecting future prices
- Trend indicators showing price direction

### Inventory System
- Gold-based currency system
- Buy/sell functionality
- Item quantity tracking
- Visual inventory slots

### Visual Feedback
- **Price Sparklines**: Mini graphs showing historical price trends
- **Trend Icons**: Visual indicators for price increases/decreases
- **Tooltips**: Hover information for items
- **Status Labels**: Real-time transaction feedback

## Controls

When running the test scene (`TestShop.gd`):

| Key | Action |
|-----|--------|
| **Mouse Click** | Purchase selected item (1x quantity) |
| **S** | Sell test item (demonstrates price decrease) |
| **R** | Reset purchase/sell history |

## Usage

### Running the Project

1. Open the project in Godot 4.5+
2. Set `Main_World.tscn` or `TestShop.gd` as the main scene
3. Press F5 to run

### Test Scene Features

The included test scene (`TestShop.gd`) provides:
- Starting gold: 1000
- Sample junk food store items
- Real-time gold and status displays
- Manual testing controls (keyboard shortcuts)

## Architecture

### Core Classes

- **`DynamicShop`**: Main shop logic handling buy/sell transactions and price calculations
- **`DynamicShopItem`**: Item data structure with ID, name, description, category, icon, and pricing info
- **`ShopItemPanel`**: UI component displaying individual shop items
- **`ShopDisplay`**: Controller managing the shop UI layout and interactions
- **`InventoryManager`**: Handles player inventory state
- **`PriceHistorySparkline`**: Renders price history as a visual graph

### Signals

The system uses Godot signals for decoupled communication:
- `item_purchased(item_id, quantity, final_price)`
- `item_sold(item_id, quantity, final_price)`
- `item_clicked(item_id)`
- `item_hovered(item_id, is_hovered)`

## Assets

Included sample assets:
- Food items: Burger, Chips, Choco, Fries
- Potions: Health Potion
- Fish varieties: Orange Fish, Redfin, Salmonella, King Fish
- Enemies: Green Slime, Boss variants
- Miscellaneous images

## Plugin

**TokoKuBetterThanMeduro** (`addons/Waijo/`)
- Custom editor plugin for enhanced shop functionality
- Description: "Gaperlu jek awal kok iki" (Javanese: "No need from the start")

## Configuration

### Display Settings
- Viewport: 640x360
- Stretch Mode: Viewport
- Aspect Ratio: Expand

### Project Features
- Godot 4.5 compatibility
- Forward Plus rendering pipeline

## License

This project appears to be a personal/educational project ("Test TA" suggests "Tugas Akhir" - final project in Indonesian).

## Notes

- The project includes Indonesian/Javanese text in various places
- Some asset filenames contain informal/meme references
- The system is designed for educational/demonstration purposes
