import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/cart_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../core/localization/app_localizations.dart';
import 'home/home_view.dart';
import 'orders/orders_history_view.dart';
import 'support/support_view.dart';
import 'settings/settings_view.dart';
import 'cart/cart_view.dart';
import 'courier/courier_orders_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);
    final cartVM = Provider.of<CartViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final primary = theme.colorScheme.primary;
    final screens = <Widget>[
      const HomeView(),
      const OrdersHistoryView(),
      if (authVM.isApprovedCourier) const CourierOrdersView(),
      const SupportView(),
      const SettingsView(),
    ];
    if (_currentIndex >= screens.length) _currentIndex = 0;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartView()),
          );
        },
        backgroundColor: primary,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 26),
            if (cartVM.itemCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${cartVM.itemCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home_rounded),
            label: loc.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long_rounded),
            label: loc.isArabic ? 'طلباتي' : 'Orders',
          ),
          if (authVM.isApprovedCourier)
            BottomNavigationBarItem(
              icon: const Icon(Icons.delivery_dining_outlined),
              activeIcon: const Icon(Icons.delivery_dining_rounded),
              label: loc.isArabic ? 'المندوب' : 'Courier',
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.support_agent_outlined),
            activeIcon: const Icon(Icons.support_agent_rounded),
            label: loc.translate('support'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings_rounded),
            label: loc.translate('settings'),
          ),
        ],
      ),
    );
  }
}
