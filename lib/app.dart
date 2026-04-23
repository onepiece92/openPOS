import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_app/features/backup/presentation/backup_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pos_app/core/providers/hive_provider.dart';
import 'package:pos_app/core/theme/app_theme.dart';
import 'package:pos_app/features/audit/presentation/audit_log_screen.dart';
import 'package:pos_app/features/help/presentation/learn_screen.dart';
import 'package:pos_app/features/help/presentation/shortcuts_screen.dart';
import 'package:pos_app/features/help/presentation/support_screen.dart';
import 'package:pos_app/features/cart/presentation/cart_detail_screen.dart';
import 'package:pos_app/features/cart/presentation/home.dart';
import 'package:pos_app/features/cart/presentation/payment_screen.dart';
import 'package:pos_app/features/customers/presentation/customers_screen.dart';
import 'package:pos_app/features/expenses/presentation/expenses_screen.dart';
import 'package:pos_app/features/inventory/presentation/inventory_screen.dart';
import 'package:pos_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pos_app/features/orders/presentation/order_detail_screen.dart';
import 'package:pos_app/features/orders/presentation/orders_screen.dart';
import 'package:pos_app/features/printing/presentation/printer_setup_screen.dart';
import 'package:pos_app/features/products/presentation/categories_screen.dart';
import 'package:pos_app/features/products/presentation/product_form_screen.dart';
import 'package:pos_app/features/products/presentation/products_screen.dart';
import 'package:pos_app/features/receipts/presentation/receipt_screen.dart';
import 'package:pos_app/features/reports/presentation/dashboard_screen.dart';
import 'package:pos_app/features/settings/presentation/settings_screen.dart';
import 'package:pos_app/features/settings/presentation/store_profile_edit_screen.dart';
import 'package:pos_app/features/tax/presentation/tax_settings_screen.dart';
import 'package:pos_app/features/theme/presentation/theme_notifier.dart';
import 'package:pos_app/features/theme/presentation/theme_preview_screen.dart';

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      ),
    );

class POSApp extends ConsumerWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Open POS : Offline',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient(brightness),
          ),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
                final loc =
                    router.routerDelegate.currentConfiguration.uri.toString();
                if (loc != '/help/shortcuts') router.push('/help/shortcuts');
              },
              const SingleActivator(LogicalKeyboardKey.slash,
                  meta: true, shift: true): () {
                final loc =
                    router.routerDelegate.currentConfiguration.uri.toString();
                if (loc != '/help/shortcuts') router.push('/help/shortcuts');
              },
              const SingleActivator(LogicalKeyboardKey.keyH, meta: true): () =>
                  router.go('/pos'),
              const SingleActivator(LogicalKeyboardKey.keyP, meta: true): () =>
                  router.go('/products'),
              const SingleActivator(LogicalKeyboardKey.keyO, meta: true): () =>
                  router.go('/orders'),
              const SingleActivator(LogicalKeyboardKey.keyU, meta: true): () =>
                  router.go('/customers'),
              const SingleActivator(LogicalKeyboardKey.keyE, meta: true): () =>
                  router.go('/expenses'),
              const SingleActivator(LogicalKeyboardKey.comma, meta: true): () =>
                  router.go('/settings'),
              const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
                  router.push('/products/add'),
              const SingleActivator(LogicalKeyboardKey.keyI, meta: true): () =>
                  router.push('/inventory'),
              const SingleActivator(LogicalKeyboardKey.keyW, meta: true): () {
                if (router.canPop()) router.pop();
              },
            },
            child: child!,
          ),
        );
      },
      routerConfig: router,
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final isOnboarded = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/pos',
    redirect: (context, state) {
      if (!isOnboarded && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, state) => _slide(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/pos',
        pageBuilder: (_, state) => _slide(state, const CartScreen()),
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (_, state) => _slide(state, const CartDetailScreen()),
      ),
      GoRoute(
        path: '/payment',
        pageBuilder: (_, state) => _slide(state, const PaymentScreen()),
      ),
      GoRoute(
        path: '/receipt/:orderId',
        pageBuilder: (_, state) => _slide(
          state,
          ReceiptScreen(
            orderId: int.parse(state.pathParameters['orderId']!),
          ),
        ),
      ),
      GoRoute(
        path: '/products',
        pageBuilder: (_, state) => _slide(state, const ProductsScreen()),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (_, state) => _slide(state, const ProductFormScreen()),
          ),
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => _slide(
              state,
              ProductFormScreen(
                productId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/categories',
        pageBuilder: (_, state) => _slide(state, const CategoriesScreen()),
      ),
      GoRoute(
        path: '/inventory',
        pageBuilder: (_, state) => _slide(state, const InventoryScreen()),
      ),
      GoRoute(
        path: '/customers',
        pageBuilder: (_, state) => _slide(state, const CustomersScreen()),
      ),
      GoRoute(
        path: '/expenses',
        pageBuilder: (_, state) => _slide(state, const ExpensesScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (_, state) => _slide(state, const DashboardScreen()),
      ),
      GoRoute(
        path: '/tax',
        pageBuilder: (_, state) => _slide(state, const TaxSettingsScreen()),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (_, state) => _slide(state, const OrdersScreen()),
        routes: [
          GoRoute(
            path: ':id',
            pageBuilder: (_, state) => _slide(
              state,
              OrderDetailScreen(
                orderId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/audit',
        pageBuilder: (_, state) => _slide(state, const AuditLogScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slide(state, const SettingsScreen()),
        routes: [
          GoRoute(
            path: 'profile',
            pageBuilder: (_, state) =>
                _slide(state, const StoreProfileEditScreen()),
          ),
          GoRoute(
            path: 'backup',
            pageBuilder: (_, state) => _slide(state, const BackupScreen()),
          ),
          GoRoute(
            path: 'printer',
            pageBuilder: (_, state) =>
                _slide(state, const PrinterSetupScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/theme/preview',
        pageBuilder: (_, state) => _slide(state, const ThemePreviewScreen()),
      ),
      GoRoute(
        path: '/help/support',
        pageBuilder: (_, state) => _slide(state, const SupportScreen()),
      ),
      GoRoute(
        path: '/help/learn',
        pageBuilder: (_, state) => _slide(state, const LearnScreen()),
      ),
      GoRoute(
        path: '/help/shortcuts',
        pageBuilder: (_, state) => _slide(state, const ShortcutsScreen()),
      ),
    ],
  );
});
