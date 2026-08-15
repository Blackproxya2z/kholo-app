/// One item in the user's persistent cart.
class CartItem {
  final String productId;
  int quantity;

  CartItem({required this.productId, this.quantity = 1});

  CartItem copyWith({int? quantity}) =>
      CartItem(productId: productId, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['productId'] as String,
    quantity: json['quantity'] as int? ?? 1,
  );
}
