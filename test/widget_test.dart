import 'package:flutter_test/flutter_test.dart';
import 'package:commerce_multistore_app/main.dart';
import 'package:provider/provider.dart';

import 'package:commerce_multistore_app/viewmodels/theme_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/localization_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/auth_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/products_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/cart_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/orders_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/delivery_viewmodel.dart';
import 'package:commerce_multistore_app/viewmodels/notifications_viewmodel.dart';

void main() {
  testWidgets('App smoke test loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeViewModel()),
          ChangeNotifierProvider(create: (_) => LocalizationViewModel()),
          ChangeNotifierProvider(create: (_) => AuthViewModel()),
          ChangeNotifierProvider(create: (_) => ProductsViewModel()),
          ChangeNotifierProvider(create: (_) => CartViewModel()),
          ChangeNotifierProvider(create: (_) => OrdersViewModel()),
          ChangeNotifierProvider(create: (_) => DeliveryViewModel()),
          ChangeNotifierProvider(create: (_) => NotificationsViewModel()),
        ],
        child: const MultiStoreCommerceApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(MultiStoreCommerceApp), findsOneWidget);
  });
}
