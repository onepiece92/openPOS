# Project Roadmap - Offline-First POS

This roadmap outlines the path to a production-ready, offline-first POS application.

## Milestone 1: v1 (Foundation & Core POS)

### Phase 1: Core Foundation & Shared Logic (CURRENT)
- [ ] Implement robust `core/theme` (Vibrant palettes, dark mode).
- [ ] Finalize `core/database/tables` (Relationships, foreign keys).
- [ ] Set up `shared/widgets` (Buttons, inputs, glassmorphism containers).
- [ ] Standardize `core/utils` (Currency, date, printer helpers).

### Phase 2: User Onboarding & Store Configuration
- [ ] Built-in setup flow (Store name, currency, branding).
- [ ] Hive-based persistent config.
- [ ] Printer discovery and test printing.

### Phase 3: Product Management (The Catalog)
- [ ] CRUD for Categories and Products.
- [ ] Pricing logic (Fixed, variable).
- [ ] Grid vs. List views for product selection.

### Phase 4: POS Interface (Main Flow)
- [ ] Interactive cart with swipe-to-delete.
- [ ] Quick-action modifiers (Discount, tax).
- [ ] Multi-payment support (Cash, Local Wallet, Card).
- [ ] Order completion with Drift transaction safety.

### Phase 5: Hardware Deep Integration
- [ ] Real-time printer status monitoring.
- [ ] Automatic PDF generation.
- [ ] Thermal paper format optimization (ESC/POS).

### Phase 6: Order History & Local Reporting
- [ ] Searchable order history with filter by date.
- [ ] Sales summaries (Daily, weekly).
- [ ] Exporting to CSV/PDF.

### Phase 7: Polish & Power Features
- [ ] Keyboard shortcuts for desktop users.
- [ ] Micro-animations for feedback (Success/Failure).
- [ ] Held orders (Hive-based snapshots).

### Phase 8: Final Stabilization
- [ ] Performance audit (Drift queries, UI frame rates).
- [ ] Error boundary implementation.
- [ ] Production-ready build testing.

---

## Future Milestones
- **v2:** Cloud synchronization and Multi-terminal support.
- **v3:** Advanced Inventory & Supplier Management.
