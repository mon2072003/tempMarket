import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  final String? selectedNote;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.selectedNote,
  });

  double get totalPrice => product.price * quantity;
}
