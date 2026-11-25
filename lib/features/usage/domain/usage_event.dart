/// The parts of Open POS a shopkeeper can ask us to improve. Every
/// [UsageEvent] belongs to exactly one of them.
enum FeatureArea {
  selling('Selling'),
  receiptsPrinting('Receipts & printing'),
  productsStock('Products & stock'),
  customersLoyalty('Customers & loyalty'),
  reports('Reports'),
  expenses('Expenses'),
  backup('Backup'),
  importExport('Import/export'),
  other('Other');

  const FeatureArea(this.label);

  /// Fixed UI label; also the only way an area appears in a usage summary.
  final String label;
}

/// Everything the on-device usage counter can count. Counters are keyed by
/// this enum ONLY (its `name` is the Hive key and the label in the summary),
/// so no free-form key or value can ever be stored or sent.
///
/// `screen…` events count a screen being opened (see [usageEventForRoute]);
/// the rest are counted where the action completes.
enum UsageEvent {
  // Selling
  screenSell(FeatureArea.selling),
  screenPayment(FeatureArea.selling),
  screenOrders(FeatureArea.selling),
  screenOrderDetail(FeatureArea.selling),
  screenTables(FeatureArea.selling),
  saleCompleted(FeatureArea.selling),
  refundIssued(FeatureArea.selling),
  orderVoided(FeatureArea.selling),
  ticketHeld(FeatureArea.selling),
  discountApplied(FeatureArea.selling),
  productSearched(FeatureArea.selling),

  // Receipts & printing
  screenReceipt(FeatureArea.receiptsPrinting),
  screenPrinterSetup(FeatureArea.receiptsPrinting),
  receiptPrinted(FeatureArea.receiptsPrinting),
  receiptShared(FeatureArea.receiptsPrinting),

  // Products & stock
  screenProducts(FeatureArea.productsStock),
  screenProductForm(FeatureArea.productsStock),
  screenCategories(FeatureArea.productsStock),
  screenInventory(FeatureArea.productsStock),

  // Customers & loyalty
  screenCustomers(FeatureArea.customersLoyalty),
  customerAddedToSale(FeatureArea.customersLoyalty),
  loyaltyPointsRedeemed(FeatureArea.customersLoyalty),

  // Reports
  reportViewed(FeatureArea.reports),

  // Expenses
  screenExpenses(FeatureArea.expenses),
  expenseAdded(FeatureArea.expenses),

  // Backup
  screenBackup(FeatureArea.backup),
  backupCreated(FeatureArea.backup),
  backupRestored(FeatureArea.backup),

  // Import/export
  csvImported(FeatureArea.importExport),
  csvExported(FeatureArea.importExport),

  // Other
  screenSettings(FeatureArea.other),
  screenStoreProfile(FeatureArea.other),
  screenTaxSettings(FeatureArea.other),
  screenAuditLog(FeatureArea.other),
  screenHelp(FeatureArea.other);

  const UsageEvent(this.area);

  final FeatureArea area;

  /// The events of [area], in declaration order.
  static List<UsageEvent> of(FeatureArea area) => [
        for (final e in values)
          if (e.area == area) e
      ];
}

/// Screen-open event for a go_router route template (`fullPath`), or null
/// for routes that are not counted (onboarding, the cart sheet, this
/// feedback screen itself, theme preview).
UsageEvent? usageEventForRoute(String? fullPath) => switch (fullPath) {
      '/pos' => UsageEvent.screenSell,
      '/payment' => UsageEvent.screenPayment,
      '/orders' => UsageEvent.screenOrders,
      '/orders/:id' => UsageEvent.screenOrderDetail,
      '/tables' => UsageEvent.screenTables,
      '/receipt/:orderId' => UsageEvent.screenReceipt,
      '/settings/printer' => UsageEvent.screenPrinterSetup,
      '/products' => UsageEvent.screenProducts,
      '/products/add' || '/products/:id' => UsageEvent.screenProductForm,
      '/categories' => UsageEvent.screenCategories,
      '/inventory' => UsageEvent.screenInventory,
      '/customers' => UsageEvent.screenCustomers,
      '/reports' => UsageEvent.reportViewed,
      '/expenses' => UsageEvent.screenExpenses,
      '/settings/backup' => UsageEvent.screenBackup,
      '/settings' => UsageEvent.screenSettings,
      '/settings/profile' => UsageEvent.screenStoreProfile,
      '/tax' => UsageEvent.screenTaxSettings,
      '/audit' => UsageEvent.screenAuditLog,
      '/help/support' ||
      '/help/learn' ||
      '/help/shortcuts' =>
        UsageEvent.screenHelp,
      _ => null,
    };
