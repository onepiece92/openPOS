import { useState } from "react";

const interStyle = `
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
  * { box-sizing: border-box; }
  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: #334155; border-radius: 3px; }
`;

const sections = [
  {
    id: "core",
    label: "Core Sales",
    color: "#F59E0B",
    features: [
      { feature: "Product Catalog Browser", description: "Grid/list view of products with image, name, price, stock", priority: "P0", offline: "✅ Full", storage: "SQLite / Drift", notes: "Category filters, search, barcode scan" },
      { feature: "Cart Management", description: "Add/remove/update quantities, apply discounts per line item", priority: "P0", offline: "✅ Full", storage: "In-memory + Hive", notes: "Multi-cart / tab support" },
      { feature: "Checkout Flow", description: "Review order, select payment method, confirm sale", priority: "P0", offline: "✅ Full", storage: "SQLite", notes: "Tax calculation at checkout" },
      { feature: "Cash Payment", description: "Enter tendered amount, compute change due", priority: "P0", offline: "✅ Full", storage: "SQLite", notes: "Denomination breakdown optional" },
      { feature: "Card Payment (offline)", description: "Record card transaction reference manually if reader offline", priority: "P1", offline: "⚠️ Partial", storage: "SQLite", notes: "Stripe Terminal supports offline auth" },
      { feature: "Split Payment", description: "Pay portion by cash, portion by card/other method", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Track each tender separately" },
      { feature: "Discounts & Coupons", description: "Percentage or flat-amount discounts at line or order level", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Coupon code lookup requires local cache" },
      { feature: "Hold & Resume Orders", description: "Park an open order and start a new one", priority: "P1", offline: "✅ Full", storage: "Hive / SQLite", notes: "Useful for busy counters" },
      { feature: "Order Notes / Special Instructions", description: "Free-text notes attached to order or line item", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "Printed on kitchen/receipt" },
      { feature: "Barcode / QR Scanner", description: "Scan product barcodes to add to cart instantly", priority: "P0", offline: "✅ Full", storage: "Local SKU map", notes: "flutter_barcode_scanner or mobile_scanner" },
    ]
  },
  {
    id: "products",
    label: "Product Management",
    color: "#10B981",
    features: [
      { feature: "Product CRUD", description: "Create, edit, delete products with name, price, SKU, images", priority: "P0", offline: "✅ Full", storage: "SQLite + File system", notes: "Images stored locally" },
      { feature: "Categories & Subcategories", description: "Hierarchical product organization", priority: "P0", offline: "✅ Full", storage: "SQLite", notes: "Drag-to-reorder optional" },
      { feature: "Variants / Modifiers", description: "Size, color, add-ons per product (e.g., burger toppings)", priority: "P0", offline: "✅ Full", storage: "SQLite (variant tables)", notes: "Key differentiator for F&B" },
      { feature: "Composite / Bundle Items", description: "Bundle multiple SKUs into one sellable item", priority: "P1", offline: "✅ Full", storage: "SQLite (BOM table)", notes: "Auto-deducts component stock" },
      { feature: "Price Tiers / Pricelists", description: "Different prices per customer type or time of day", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "E.g., wholesale vs retail" },
      { feature: "Product Images", description: "Offline-accessible photos for catalog view", priority: "P1", offline: "✅ Full", storage: "Device file system", notes: "Synced from cloud when online" },
      { feature: "Favorites / Quick-Access Grid", description: "Pin frequently sold items to a fast-access screen", priority: "P1", offline: "✅ Full", storage: "Hive preferences", notes: "Speeds up checkout" },
      { feature: "Import Products via CSV", description: "Bulk upload products from spreadsheet", priority: "P2", offline: "✅ Full", storage: "SQLite batch insert", notes: "Validate SKU uniqueness" },
    ]
  },
  {
    id: "inventory",
    label: "Inventory",
    color: "#6366F1",
    features: [
      { feature: "Stock Level Tracking", description: "Real-time deduction on each sale", priority: "P0", offline: "✅ Full", storage: "SQLite", notes: "Negative stock flag configurable" },
      { feature: "Low Stock Alerts", description: "Notify cashier/admin when stock drops below threshold", priority: "P1", offline: "✅ Full", storage: "SQLite + local notify", notes: "flutter_local_notifications" },
      { feature: "Stock Adjustment", description: "Manual +/- adjustments with reason code (damage, shrink)", priority: "P1", offline: "✅ Full", storage: "SQLite (adjustment log)", notes: "Audit trail required" },
      { feature: "Stock Take / Count", description: "Physical count wizard; compare expected vs actual", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Freeze stock during count option" },
      { feature: "Purchase Orders (Receiving)", description: "Receive stock from suppliers; update inventory", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "Sync supplier catalog when online" },
      { feature: "Wastage / Spoilage Tracking", description: "Log items discarded (food expiry, breakage)", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "Categorize by reason" },
      { feature: "Multi-Location Stock", description: "Track stock per location/store independently", priority: "P2", offline: "✅ Full", storage: "SQLite (location_id FK)", notes: "Transfer requests when online" },
    ]
  },
  {
    id: "customers",
    label: "Customer Management",
    color: "#EC4899",
    features: [
      { feature: "Customer Profiles", description: "Name, phone, email, address, loyalty points", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Link transactions to customer" },
      { feature: "Customer Search at POS", description: "Look up customer by name/phone during checkout", priority: "P1", offline: "✅ Full", storage: "SQLite FTS", notes: "Full-text search locally" },
      { feature: "Loyalty Points", description: "Earn points per purchase; redeem at checkout", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Configurable earn/redeem rates" },
      { feature: "Customer Purchase History", description: "View all past orders for a customer", priority: "P2", offline: "✅ Full", storage: "SQLite JOIN", notes: "Useful for service/returns" },
      { feature: "Customer Groups / Tags", description: "Segment customers for targeted discounts", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "Tag-based pricelist triggers" },
      { feature: "Account / House Credit", description: "Allow customer to buy on credit, settle later", priority: "P2", offline: "✅ Full", storage: "SQLite (ledger)", notes: "Credit limit enforcement" },
    ]
  },
  {
    id: "receipts",
    label: "Receipts & Printing",
    color: "#F97316",
    features: [
      { feature: "Digital Receipt (in-app)", description: "On-screen receipt after each completed sale", priority: "P0", offline: "✅ Full", storage: "SQLite", notes: "PDF export optional" },
      { feature: "Thermal Printer Receipt", description: "Print to Bluetooth/USB/WiFi thermal printer", priority: "P0", offline: "✅ Full", storage: "ESC/POS commands", notes: "esc_pos_utils + blue_thermal_printer" },
      { feature: "Receipt Customization", description: "Logo, store name, footer message, tax number", priority: "P1", offline: "✅ Full", storage: "Hive preferences", notes: "Template editor" },
      { feature: "Email / SMS Receipt", description: "Send receipt to customer email or phone", priority: "P1", offline: "⚠️ Queue", storage: "Outbox queue", notes: "Delivered when connectivity restored" },
      { feature: "Kitchen Printer / KDS", description: "Print order tickets to kitchen printer", priority: "P1", offline: "✅ Full", storage: "Print queue", notes: "Critical for F&B" },
      { feature: "Reprint Last Receipt", description: "Reprint any past receipt from order history", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Gift receipt variant option" },
      { feature: "QR Code on Receipt", description: "Encode order ID or feedback link as QR", priority: "P2", offline: "✅ Full", storage: "Generated locally", notes: "qr_flutter package" },
    ]
  },
  {
    id: "expenses",
    label: "Expenses & Payments",
    color: "#F43F5E",
    features: [
      { feature: "Expense Entry", description: "Log business expenses with amount, date, category, and notes", priority: "P0", offline: "✅ Full", storage: "SQLite (expenses table)", notes: "Quick-add from POS home screen" },
      { feature: "Expense Categories", description: "Predefined and custom categories (rent, utilities, wages, supplies)", priority: "P0", offline: "✅ Full", storage: "SQLite", notes: "Color-coded per category" },
      { feature: "Receipt Photo Capture", description: "Attach camera photo of paper receipt to expense record", priority: "P1", offline: "✅ Full", storage: "Device file system", notes: "image_picker package; synced to cloud" },
      { feature: "Recurring Expenses", description: "Auto-log fixed recurring costs (rent, subscriptions) on schedule", priority: "P1", offline: "✅ Full", storage: "SQLite + workmanager", notes: "Monthly/weekly frequency" },
      { feature: "Expense Approval Workflow", description: "Staff submits expense; manager approves or rejects", priority: "P2", offline: "✅ Full", storage: "SQLite (status column)", notes: "Sync approval to cloud when online" },
      { feature: "Petty Cash Tracking", description: "Dedicated petty cash ledger with opening balance and transactions", priority: "P1", offline: "✅ Full", storage: "SQLite (ledger table)", notes: "Cash in / cash out per entry" },
      { feature: "Supplier / Vendor Tagging", description: "Tag expenses to a supplier for vendor spend analysis", priority: "P2", offline: "✅ Full", storage: "SQLite (vendor_id FK)", notes: "Links to purchase order module" },
      { feature: "Tax-Deductible Flag", description: "Mark expense as tax-deductible for accounting export", priority: "P2", offline: "✅ Full", storage: "SQLite (boolean column)", notes: "Useful for accountant export" },
      { feature: "Expense vs Revenue Report", description: "P&L summary comparing sales revenue against logged expenses", priority: "P1", offline: "✅ Full", storage: "SQLite aggregation", notes: "Period selector (day/week/month)" },
      { feature: "CSV / PDF Export", description: "Export expense log for accountant or tax filing", priority: "P1", offline: "✅ Full", storage: "csv / pdf_flutter", notes: "Filter by date range and category" },
      { feature: "Cash Drawer Integration", description: "Auto-open cash drawer on cash transactions", priority: "P1", offline: "✅ Full", storage: "ESC/POS trigger", notes: "Via printer port" },
      { feature: "Cash Reconciliation / X-Report", description: "Count drawer; compare expected vs actual cash", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Per shift" },
      { feature: "Stripe Terminal (offline mode)", description: "Process card payments; queue if offline", priority: "P1", offline: "⚠️ Partial", storage: "Stripe SDK local cache", notes: "Up to ~$200 offline limit" },
      { feature: "Gift Cards (local)", description: "Issue and redeem local gift card codes", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "Encrypted code generation" },
      { feature: "Mobile Wallets (GCash, M-Pesa)", description: "Offline receipt acknowledgement, sync payment later", priority: "P2", offline: "⚠️ Record only", storage: "SQLite + sync queue", notes: "Verification on connectivity" },
      { feature: "Refunds & Returns", description: "Partial or full refund; restock inventory optionally", priority: "P0", offline: "✅ Full", storage: "SQLite (return table)", notes: "Original transaction reference" },
      { feature: "Void Transaction", description: "Cancel a completed transaction before close of day", priority: "P0", offline: "✅ Full", storage: "SQLite soft delete", notes: "Manager PIN required" },
    ]
  },
  {
    id: "reports",
    label: "Reports & Analytics",
    color: "#EF4444",
    features: [
      { feature: "Sales Summary Dashboard", description: "Today / week / month totals, top products, revenue", priority: "P0", offline: "✅ Full", storage: "SQLite aggregation", notes: "Recharts-style local charts" },
      { feature: "Product Sales Report", description: "Units sold, revenue, COGS per product", priority: "P1", offline: "✅ Full", storage: "SQLite GROUP BY", notes: "Exportable to CSV" },
      { feature: "Category Report", description: "Performance by product category", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Drill-down support" },
      { feature: "Hourly Sales Heatmap", description: "Identify peak hours during the day", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "Staffing insight" },
      { feature: "Staff Performance Report", description: "Sales per cashier per shift", priority: "P2", offline: "✅ Full", storage: "SQLite", notes: "KPI tracking" },
      { feature: "Tax Report", description: "Tax collected by type (GST, VAT) per period", priority: "P1", offline: "✅ Full", storage: "SQLite", notes: "Compliance requirement" },
      { feature: "Export to CSV / PDF", description: "Download any report as file", priority: "P1", offline: "✅ Full", storage: "csv/pdf_flutter", notes: "Share via device apps" },
    ]
  },
  {
    id: "sync",
    label: "Offline-First & Sync",
    color: "#0EA5E9",
    features: [
      { feature: "Local SQLite Database (Drift)", description: "Primary data store, all operations work locally", priority: "P0", offline: "✅ Full", storage: "drift (SQLite ORM)", notes: "Type-safe Dart ORM" },
      { feature: "Conflict-Free Sync (CRDT)", description: "Merge offline changes from multiple devices without conflicts", priority: "P0", offline: "✅ Full", storage: "CRDT / timestamp-based", notes: "Consider PowerSync or custom" },
      { feature: "Background Sync Queue", description: "Queue failed API calls (payments, loyalty) for retry", priority: "P0", offline: "✅ Full", storage: "SQLite outbox table", notes: "workmanager package" },
      { feature: "Connectivity Detection", description: "Monitor network status; switch online/offline modes", priority: "P0", offline: "✅ Full", storage: "connectivity_plus", notes: "UI indicator for staff" },
      { feature: "Delta Sync (Changed Records Only)", description: "Sync only records updated since last sync timestamp", priority: "P1", offline: "✅ Full", storage: "updated_at columns", notes: "Minimizes bandwidth" },
      { feature: "Sync Status Indicator", description: "Show pending items count and last sync time to user", priority: "P1", offline: "✅ Full", storage: "Hive / state mgmt", notes: "Trust signal for staff" },
      { feature: "Multi-Device Conflict Resolution UI", description: "Let admin resolve rare conflicts manually", priority: "P2", offline: "⚠️ Online only", storage: "Cloud DB", notes: "Edge case handling" },
      { feature: "PowerSync / Supabase Integration", description: "Real-time sync layer with offline-first guarantee", priority: "P1", offline: "✅ Full", storage: "PowerSync SDK", notes: "Purpose-built for this use case" },
      { feature: "Schema Migration (Drift)", description: "Versioned database migrations executed automatically on app upgrade", priority: "P0", offline: "✅ Full", storage: "Drift MigrationStrategy", notes: "schemaVersion bump + migration callbacks; test with each release" },
      { feature: "Seed Data on First Install", description: "Pre-populate default tax rates, expense categories, and sample products on fresh install", priority: "P1", offline: "✅ Full", storage: "SQLite batch insert", notes: "Idempotent; skipped if data already exists" },
      { feature: "Data Integrity Checks", description: "On app start, verify FK constraints and orphan records; auto-repair common issues", priority: "P1", offline: "✅ Full", storage: "SQLite PRAGMA integrity_check", notes: "Log issues to audit trail; alert if critical" },
    ]
  },
  {
    id: "signin",
    label: "Sign In & Backup",
    color: "#38BDF8",
    features: [
      { feature: "Single-User Account (Email + Password)", description: "One owner account; email/password sign-in via Supabase Auth or Firebase", priority: "P0", offline: "⚠️ Online first", storage: "Supabase Auth / Firebase Auth", notes: "Token cached locally for offline re-entry" },
      { feature: "Biometric / PIN App Lock", description: "Lock app on launch or after timeout; unlock with fingerprint or PIN", priority: "P0", offline: "✅ Full", storage: "local_auth + flutter_secure_storage", notes: "No network needed after first sign-in" },
      { feature: "Persistent Session (Stay Logged In)", description: "Refresh token stored securely so user stays signed in between sessions", priority: "P0", offline: "✅ Full", storage: "flutter_secure_storage", notes: "Token refresh on reconnect" },
      { feature: "Auto Cloud Backup", description: "Automatically upload encrypted DB snapshot to user's cloud storage on schedule", priority: "P0", offline: "⚠️ Online only", storage: "Supabase Storage / Google Drive API", notes: "workmanager for background trigger" },
      { feature: "Manual Backup Now", description: "One-tap button to push a backup immediately", priority: "P0", offline: "⚠️ Online only", storage: "Supabase Storage", notes: "Shows last backup timestamp" },
      { feature: "Restore from Backup", description: "Download latest cloud backup and restore DB on new or reset device", priority: "P0", offline: "⚠️ Online only", storage: "Supabase Storage + SQLite", notes: "Confirmation dialog before overwrite" },
      { feature: "Local Backup Export", description: "Export encrypted DB file to device storage or share via Files app", priority: "P1", offline: "✅ Full", storage: "path_provider + share_plus", notes: "Fallback when no internet" },
      { feature: "Backup History", description: "List of past backup snapshots with date, size, and restore option", priority: "P1", offline: "⚠️ Online only", storage: "Supabase Storage metadata", notes: "Keep last 10 snapshots" },
      { feature: "Account Profile", description: "View and edit owner name, business name, email; change password", priority: "P1", offline: "⚠️ Online only", storage: "Supabase Auth", notes: "Profile photo optional" },
      { feature: "Sign Out & Data Wipe", description: "Sign out and optionally wipe all local data from device", priority: "P1", offline: "✅ Full", storage: "SQLite drop + Hive clear", notes: "Requires confirmation; backup prompt shown first" },
    ]
  },
  {
    id: "hardware",
    label: "Hardware Integration",
    color: "#A16207",
    features: [
      { feature: "Bluetooth Thermal Printer", description: "Print receipts over Bluetooth (Star, Epson, Bixolon)", priority: "P1", offline: "✅ Full", storage: "blue_thermal_printer", notes: "ESC/POS standard" },
      { feature: "USB / Network Printer", description: "Print to USB-connected or WiFi LAN printer", priority: "P1", offline: "✅ Full", storage: "esc_pos_utils", notes: "Network not needed for local" },
      { feature: "Barcode Scanner (HID/BT)", description: "External Bluetooth or USB HID scanner support", priority: "P2", offline: "✅ Full", storage: "HID keyboard emulation", notes: "flutter_blue_plus / HID" },
      { feature: "Cash Drawer", description: "Kick drawer via printer port (RJ11)", priority: "P1", offline: "✅ Full", storage: "ESC/POS DLE EOT", notes: "No separate driver needed" },
      { feature: "Customer Display / Pole Display", description: "Second screen showing item and total to customer", priority: "P3", offline: "✅ Full", storage: "Serial / secondary display", notes: "VFD or 2nd device via BT" },
      { feature: "Card Reader (Stripe Terminal)", description: "Physical Stripe card reader (BBPOS WisePOS)", priority: "P3", offline: "⚠️ Partial", storage: "Stripe Terminal SDK", notes: "Offline mode for small amounts" },
      { feature: "Weight Scale Integration", description: "Read weight from USB/BT scale for priced-by-weight items", priority: "P3", offline: "✅ Full", storage: "Serial / BT protocol", notes: "Grocery / deli use case" },
    ]
  },
  {
    id: "tax",
    label: "Tax Engine",
    color: "#0D9488",
    features: [
      { feature: "Multiple Tax Rates", description: "Define unlimited named tax rates (e.g. GST 10%, VAT 15%, Service 5%) each with own percentage", priority: "P0", offline: "✅ Full", storage: "SQLite (tax_rates table)", notes: "tax_rates: id, name, rate, type, is_active" },
      { feature: "Tax Inclusive / Exclusive Toggle", description: "Per-tax-rate setting: inclusive (tax embedded in price) or exclusive (tax added on top at checkout)", priority: "P0", offline: "✅ Full", storage: "SQLite (inclusion_type column)", notes: "Affects how displayed price and tax amount are computed" },
      { feature: "Default Tax Assignment", description: "Set a store-wide default tax rate applied to all new products automatically", priority: "P0", offline: "✅ Full", storage: "Hive (default_tax_id)", notes: "Can be overridden per product or category" },
      { feature: "Taxable Toggle per Product", description: "Mark individual products as taxable or tax-exempt; overrides category and store default", priority: "P0", offline: "✅ Full", storage: "SQLite (products.is_taxable boolean)", notes: "E.g. fresh food exempt, prepared food taxed" },
      { feature: "Tax Assignment per Product", description: "Assign one or more specific tax rates directly to a product, overriding the category default", priority: "P0", offline: "✅ Full", storage: "SQLite (product_taxes join table)", notes: "product_id + tax_rate_id many-to-many" },
      { feature: "Tax Assignment per Category", description: "Apply a default tax rate to all products in a category; products can still override", priority: "P1", offline: "✅ Full", storage: "SQLite (categories.tax_rate_id FK)", notes: "Cascades to new products added to category" },
      { feature: "Tax Groups", description: "Bundle multiple tax rates into a named group (e.g. 'Restaurant Tax' = GST + Service Charge) applied as one", priority: "P1", offline: "✅ Full", storage: "SQLite (tax_groups + tax_group_members tables)", notes: "Each member rate computed independently then summed" },
      { feature: "Compound Tax", description: "Tax-on-tax: second tax rate calculated on (price + first tax) rather than on price alone", priority: "P2", offline: "✅ Full", storage: "SQLite (is_compound boolean on tax_rate)", notes: "Common in Canada (GST + PST stacking)" },
      { feature: "Tax Rounding Rules", description: "Configure rounding mode per tax: round half-up, half-even (banker's), or truncate; applied per line or per order", priority: "P1", offline: "✅ Full", storage: "SQLite (rounding_mode column)", notes: "Prevents penny discrepancies across receipts" },
      { feature: "Tax-Exempt Customers", description: "Flag a customer record as tax-exempt; checkout automatically skips tax calculation for that customer", priority: "P2", offline: "✅ Full", storage: "SQLite (customers.tax_exempt boolean)", notes: "Attach exemption certificate number for audit" },
      { feature: "Tax Breakdown on Receipt", description: "Print itemised tax lines on receipt showing each rate name and amount collected", priority: "P0", offline: "✅ Full", storage: "Derived from order_taxes table", notes: "Required for VAT/GST compliance in most regions" },
      { feature: "Tax Report by Rate", description: "Period report showing gross sales, taxable sales, and tax collected per named rate", priority: "P1", offline: "✅ Full", storage: "SQLite GROUP BY tax_rate_id", notes: "Exportable to CSV for accountant / BAS / VAT return" },
      { feature: "Tax Override at Checkout", description: "Manager can manually override computed tax amount on an order with reason logged", priority: "P2", offline: "✅ Full", storage: "SQLite (order_tax_override + audit_log)", notes: "Requires manager PIN; audit trail mandatory" },
    ]
  },
  {
    id: "theme",
    label: "Theme & Design",
    color: "#A855F7",
    features: [
      { feature: "Day / Night Mode Toggle", description: "Switch between light and dark base theme; persisted per session", priority: "P1", offline: "✅ Full", storage: "Hive preferences", notes: "ThemeData + ThemeMode; follows system default" },
      { feature: "Brand Kit Theme", description: "Upload store logo, pick primary & accent brand colors; all UI surfaces auto-adapt to the palette", priority: "P1", offline: "✅ Full", storage: "Hive (brand_config JSON)", notes: "color_scheme from seed color via ColorScheme.fromSeed" },
      { feature: "Brand Kit — Typography", description: "Choose from curated font pairings (display + body) that match the brand tone; preview live", priority: "P2", offline: "✅ Full", storage: "Hive (font_family key)", notes: "google_fonts package; fonts cached offline after first load" },
      { feature: "Brand Kit — Button & Corner Style", description: "Configure global corner radius (sharp / rounded / pill) and button fill style (solid / outlined / tonal)", priority: "P2", offline: "✅ Full", storage: "Hive (shape_config JSON)", notes: "Applied via ThemeData.shape globally" },
      { feature: "Minimal Theme", description: "High-contrast flat design kit: pure white/black surfaces, no shadows, tight spacing, no gradients", priority: "P1", offline: "✅ Full", storage: "Hive (theme_id: 'minimal')", notes: "Best for bright retail environments with harsh lighting" },
      { feature: "Minimal — Monochrome Palette", description: "Minimal kit variant: single accent color on greyscale base; all status indicators use shape not color alone", priority: "P2", offline: "✅ Full", storage: "Hive", notes: "WCAG AA accessible; good for accessibility-first builds" },
      { feature: "Glassmorphic Theme", description: "Frosted-glass card surfaces with blur backdrop, subtle border glow, and translucent backgrounds", priority: "P2", offline: "✅ Full", storage: "Hive (theme_id: 'glass')", notes: "BackdropFilter + ImageFilter.blur; GPU intensive — test on target device" },
      { feature: "Glassmorphic — Gradient Mesh Background", description: "Animated soft gradient mesh behind glass surfaces; shifts slowly on idle screen", priority: "P3", offline: "✅ Full", storage: "Hive", notes: "CustomPainter with lerp animation; disable on low-end devices" },
      { feature: "Glassmorphic — Depth Shadows", description: "Layered drop shadows that simulate physical depth on cards, drawers and modals", priority: "P3", offline: "✅ Full", storage: "Hive", notes: "BoxDecoration multi-layer BoxShadow" },
      { feature: "Theme Preview Screen", description: "Live full-screen preview of selected theme applied to a sample POS checkout screen before committing", priority: "P1", offline: "✅ Full", storage: "Stateless preview widget", notes: "No data written until user taps 'Apply'" },
      { feature: "Per-Screen Layout Density", description: "Toggle compact / comfortable / spacious row density independently per screen (catalog, orders, reports)", priority: "P2", offline: "✅ Full", storage: "Hive (density_map JSON)", notes: "VisualDensity in Flutter ThemeData" },
      { feature: "Custom Splash & Receipt Color", description: "Set a custom tint for the splash/loading screen and receipt header banner to match store branding", priority: "P3", offline: "✅ Full", storage: "Hive", notes: "Small delight detail; receipt uses hex-to-ESC/POS greyscale" },
    ]
  },
  {
    id: "audit",
    label: "Audit Log",
    color: "#D946EF",
    features: [
      { feature: "Transaction Audit Trail", description: "Immutable log of every sale, void, refund, and discount with before/after values", priority: "P0", offline: "✅ Full", storage: "SQLite (audit_log table)", notes: "append-only; never update or delete rows" },
      { feature: "Settings Change Log", description: "Record every change to tax rates, prices, store config with old value, new value, and timestamp", priority: "P1", offline: "✅ Full", storage: "SQLite (audit_log, entity_type='setting')", notes: "Detect accidental or malicious config changes" },
      { feature: "Inventory Adjustment Log", description: "Log all manual stock adjustments with reason code, quantity delta, and timestamp", priority: "P1", offline: "✅ Full", storage: "SQLite (stock_adjustments table)", notes: "Cross-references audit_log for traceability" },
      { feature: "Audit Log Viewer", description: "Searchable, filterable list of audit events filtered by date, entity type, and action", priority: "P1", offline: "✅ Full", storage: "SQLite FTS + pagination", notes: "Owner-only access; read-only UI" },
      { feature: "Export Audit Log", description: "Export filtered audit events to CSV for compliance or external review", priority: "P2", offline: "✅ Full", storage: "csv package", notes: "Date range + entity type filter before export" },
      { feature: "Tax Override Audit", description: "Log every manual tax override with order ID, original amount, override amount, reason, and timestamp", priority: "P0", offline: "✅ Full", storage: "SQLite (order_tax_override linked to audit_log)", notes: "Mandatory for VAT/GST compliance; PIN-gated action" },
    ]
  },
  {
    id: "onboarding",
    label: "Onboarding",
    color: "#22D3EE",
    features: [
      { feature: "First-Run Setup Wizard", description: "Step-by-step wizard on fresh install: business name, currency, timezone, default tax rate, printer", priority: "P0", offline: "✅ Full", storage: "Hive (onboarding_complete flag)", notes: "Cannot access POS home until wizard is finished" },
      { feature: "Country-Based Defaults", description: "Pick country and auto-suggest currency symbol, date format, and common tax rate (GST/VAT)", priority: "P0", offline: "✅ Full", storage: "Bundled locale JSON", notes: "User can override; drives intl package config" },
      { feature: "Printer Discovery on First Run", description: "Scan and pair Bluetooth or network printer as part of setup wizard; skippable", priority: "P1", offline: "✅ Full", storage: "Hive (printer_config)", notes: "Same flow as Settings > Printer Setup Wizard" },
      { feature: "Sample Data Option", description: "Offer to load demo products and categories so owner can explore before going live", priority: "P1", offline: "✅ Full", storage: "SQLite batch insert", notes: "Clearly labeled as demo data; one-tap wipe to start fresh" },
      { feature: "Onboarding Checklist", description: "Post-wizard checklist showing remaining setup tasks (add first product, connect printer, create backup)", priority: "P1", offline: "✅ Full", storage: "Hive (checklist_state JSON)", notes: "Dismissible; shown on home screen until all items complete" },
      { feature: "Migration Import Wizard", description: "Guided flow to import products and customers from a CSV or prior backup when switching from another POS", priority: "P2", offline: "✅ Full", storage: "SQLite batch insert + validation", notes: "Field-mapping step; duplicate SKU detection" },
    ]
  },
  {
    id: "settings",
    label: "Settings & Configuration",
    color: "#475569",
    features: [
      { feature: "Store Profile", description: "Name, address, logo, tax number, currency, timezone", priority: "P0", offline: "✅ Full", storage: "Hive", notes: "Appears on receipts" },
      { feature: "Currency & Locale", description: "Currency symbol, decimal format, date format", priority: "P0", offline: "✅ Full", storage: "Hive", notes: "intl package" },
      { feature: "Receipt Template Editor", description: "Customize receipt header/footer, font size, columns", priority: "P1", offline: "✅ Full", storage: "Hive / JSON template", notes: "Live preview" },
      { feature: "Printer Setup Wizard", description: "Discover, pair, and test printer from settings", priority: "P1", offline: "✅ Full", storage: "Hive", notes: "Print test page" },
      { feature: "Backup & Restore", description: "Export full DB backup; restore from file", priority: "P1", offline: "✅ Full", storage: "SQLite dump / zip", notes: "path_provider + share_plus" },
      { feature: "Keyboard Shortcuts (Tablet)", description: "Physical keyboard shortcuts for power cashiers", priority: "P2", offline: "✅ Full", storage: "Shortcuts widget", notes: "Flutter HardwareKeyboard" },
    ]
  },
];

const priorityColor = { P0: "#EF4444", P1: "#F59E0B", P2: "#6366F1", P3: "#64748B" };
const priorityLabel = { P0: "Critical", P1: "High", P2: "Medium", P3: "Low" };

const themes = {
  dark: {
    bg: "#0A0A0F", surface: "#0F172A", surface2: "#0D1117", border: "#1E293B",
    text: "#F8FAFC", textSub: "#94A3B8", textMuted: "#475569", textFaint: "#64748B",
    code: "#1E293B", rowAlt: "#0D1117",
  },
  light: {
    bg: "#F8FAFC", surface: "#EFF6FF", surface2: "#F1F5F9", border: "#CBD5E1",
    text: "#0F172A", textSub: "#334155", textMuted: "#64748B", textFaint: "#94A3B8",
    code: "#E2E8F0", rowAlt: "#F1F5F9",
  }
};

export default function POSFeaturePlanner() {
  const [activeSection, setActiveSection] = useState("core");
  const [filter, setFilter] = useState("All");
  const [isDark, setIsDark] = useState(true);
  const t = isDark ? themes.dark : themes.light;

  const section = sections.find(s => s.id === activeSection);
  const filtered = filter === "All" ? section.features : section.features.filter(f => f.priority === filter);
  const total = sections.reduce((a, s) => a + s.features.length, 0);

  return (
    <div style={{ fontFamily: "'Inter', sans-serif", background: t.bg, minHeight: "100vh", color: t.text, transition: "background 0.25s, color 0.25s" }}>
      <style>{interStyle}</style>

      {/* Header */}
      <div style={{ borderBottom: `1px solid ${t.border}`, padding: "18px 28px", display: "flex", alignItems: "center", justifyContent: "space-between", gap: 16, flexWrap: "wrap", background: t.surface }}>
        <div>
          <div style={{ fontSize: 10, color: t.textFaint, letterSpacing: 2, marginBottom: 3, fontWeight: 600, textTransform: "uppercase" }}>Flutter · Offline-First POS</div>
          <h1 style={{ margin: 0, fontSize: 20, fontWeight: 700, color: t.text, letterSpacing: -0.3, lineHeight: 1.2 }}>Feature Planner</h1>
        </div>
        <div style={{ display: "flex", gap: 8, alignItems: "center", flexWrap: "wrap" }}>
          {/* Priority filters */}
          <div style={{ display: "flex", gap: 6, background: t.bg, border: `1px solid ${t.border}`, borderRadius: 8, padding: "4px" }}>
            {["All", "P0", "P1", "P2", "P3"].map(p => (
              <button key={p} onClick={() => setFilter(p)} style={{
                padding: "5px 12px", borderRadius: 6, border: "none",
                background: filter === p ? (priorityColor[p] || t.text) : "transparent",
                color: filter === p ? "#fff" : t.textFaint,
                cursor: "pointer", fontSize: 12, fontFamily: "inherit", fontWeight: 600, transition: "all 0.15s"
              }}>
                {p === "All" ? "All" : p}
                {p !== "All" && <span style={{ marginLeft: 4, opacity: 0.75, fontWeight: 400 }}>{priorityLabel[p]}</span>}
              </button>
            ))}
          </div>
          {/* Theme toggle */}
          <button onClick={() => setIsDark(d => !d)} style={{
            padding: "6px 14px", borderRadius: 8, border: `1px solid ${t.border}`,
            background: t.bg, color: t.textSub,
            cursor: "pointer", fontSize: 13, fontFamily: "inherit", fontWeight: 500, display: "flex", alignItems: "center", gap: 6
          }}>
            {isDark ? "☀️" : "🌙"} <span style={{ fontSize: 12 }}>{isDark ? "Day" : "Night"}</span>
          </button>
          <div style={{ fontSize: 12, color: t.textFaint, whiteSpace: "nowrap" }}>
            <strong style={{ color: t.textSub }}>{total}</strong> features · <strong style={{ color: t.textSub }}>{sections.length}</strong> modules
          </div>
        </div>
      </div>

      <div style={{ display: "flex", height: "calc(100vh - 69px)" }}>
        {/* Sidebar */}
        <div style={{ width: 210, borderRight: `1px solid ${t.border}`, overflowY: "auto", flexShrink: 0, background: t.surface }}>
          <div style={{ padding: "12px 12px 6px", fontSize: 10, fontWeight: 700, color: t.textFaint, letterSpacing: 1.5, textTransform: "uppercase" }}>Modules</div>
          {sections.map(s => (
            <button key={s.id} onClick={() => setActiveSection(s.id)} style={{
              width: "100%", textAlign: "left", padding: "9px 14px", border: "none",
              background: activeSection === s.id ? t.bg : "transparent",
              borderLeft: `3px solid ${activeSection === s.id ? s.color : "transparent"}`,
              color: activeSection === s.id ? t.text : t.textSub,
              cursor: "pointer", fontFamily: "inherit", fontSize: 13, fontWeight: activeSection === s.id ? 600 : 400,
              display: "flex", justifyContent: "space-between", alignItems: "center", transition: "all 0.1s"
            }}>
              <span>{s.label}</span>
              <span style={{
                fontSize: 11, fontWeight: 600,
                background: activeSection === s.id ? s.color + "22" : t.border,
                color: activeSection === s.id ? s.color : t.textFaint,
                padding: "1px 8px", borderRadius: 20, minWidth: 24, textAlign: "center"
              }}>{s.features.length}</span>
            </button>
          ))}
        </div>

        {/* Main content */}
        <div style={{ flex: 1, overflowY: "auto", padding: "20px 24px" }}>
          {/* Section header */}
          <div style={{ marginBottom: 16, display: "flex", alignItems: "center", gap: 10, paddingBottom: 14, borderBottom: `2px solid ${section.color}33` }}>
            <div style={{ width: 12, height: 12, borderRadius: "50%", background: section.color, flexShrink: 0 }} />
            <h2 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: t.text }}>{section.label}</h2>
            <span style={{ fontSize: 12, color: t.textFaint, marginLeft: 2 }}>{filtered.length} features</span>
          </div>

          {/* Table */}
          <div style={{ borderRadius: 10, border: `1px solid ${t.border}`, overflow: "hidden" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 13 }}>
              <thead>
                <tr style={{ background: t.surface }}>
                  {[
                    { label: "Feature", width: "18%" },
                    { label: "Description", width: "30%" },
                    { label: "Priority", width: "9%" },
                    { label: "Offline", width: "10%" },
                    { label: "Storage / Package", width: "16%" },
                    { label: "Notes", width: "17%" },
                  ].map(h => (
                    <th key={h.label} style={{
                      padding: "10px 14px", textAlign: "left", color: t.textMuted,
                      fontWeight: 600, fontSize: 11, letterSpacing: 0.5,
                      borderBottom: `1px solid ${t.border}`, width: h.width,
                      textTransform: "uppercase"
                    }}>{h.label}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filtered.map((f, i) => (
                  <tr key={i} style={{
                    borderBottom: i < filtered.length - 1 ? `1px solid ${t.border}` : "none",
                    background: i % 2 === 0 ? "transparent" : t.rowAlt,
                    transition: "background 0.1s"
                  }}>
                    <td style={{ padding: "12px 14px", color: t.text, fontWeight: 600, fontSize: 13, lineHeight: 1.4 }}>{f.feature}</td>
                    <td style={{ padding: "12px 14px", color: t.textSub, fontSize: 13, lineHeight: 1.6 }}>{f.description}</td>
                    <td style={{ padding: "12px 14px" }}>
                      <span style={{
                        background: priorityColor[f.priority] + "18",
                        color: priorityColor[f.priority],
                        padding: "3px 10px", borderRadius: 20,
                        fontSize: 11, fontWeight: 700, display: "inline-block",
                        border: `1px solid ${priorityColor[f.priority]}44`
                      }}>{f.priority}</span>
                    </td>
                    <td style={{ padding: "12px 14px", fontSize: 13, lineHeight: 1.5 }}>
                      <span style={{ color: f.offline.startsWith("✅") ? "#16A34A" : f.offline.startsWith("⚠️") ? "#D97706" : t.textSub }}>
                        {f.offline}
                      </span>
                    </td>
                    <td style={{ padding: "12px 14px" }}>
                      <code style={{
                        background: t.code, color: section.color,
                        padding: "3px 8px", borderRadius: 5,
                        fontSize: 11, fontFamily: "'Inter', monospace", fontWeight: 500,
                        display: "inline-block", lineHeight: 1.5
                      }}>{f.storage}</code>
                    </td>
                    <td style={{ padding: "12px 14px", color: t.textFaint, fontSize: 12, lineHeight: 1.6 }}>{f.notes}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
