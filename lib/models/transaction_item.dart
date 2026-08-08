class TransactionItem {
  final int? id;
  final int? transactionId;
  final int? productId;
  final String productName;
  final int quantity;
  final String unit;

  const TransactionItem({
    this.id,
    this.transactionId,
    this.productId,
    required this.productName,
    required this.quantity,
    this.unit = 'pcs', // sensible default
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    int parseNum(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return TransactionItem(
      id: json['id'] != null ? parseNum(json['id']) : null,
      transactionId: json['transaction_id'] != null
          ? parseNum(json['transaction_id'])
          : null,
      productId:
          json['product_id'] != null ? parseNum(json['product_id']) : null,
      productName: json['product_name']?.toString() ?? 'Item',
      quantity: parseNum(json['quantity']),
      unit: json['unit']?.toString() ?? 'pcs',
    );
  }

  Map<String, dynamic> toInsertJson(int txnId) {
    return {
      'transaction_id': txnId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
