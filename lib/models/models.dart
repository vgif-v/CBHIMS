enum StockStatus { healthy, low, out }

enum TxnType { inbound, outbound }

class Product {
  final String name;
  final String sku;
  final String category;
  final int quantity;
  final int reorderPoint;
  final double unitPrice;
  final String emoji;

  const Product({
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.reorderPoint,
    required this.unitPrice,
    required this.emoji,
  });

  StockStatus get status {
    if (quantity <= 0) return StockStatus.out;
    if (quantity <= reorderPoint) return StockStatus.low;
    return StockStatus.healthy;
  }
}

class Transaction {
  final String itemName;
  final String sku;
  final String emoji;
  final TxnType type;
  final String date;
  final String status;

  const Transaction({
    required this.itemName,
    required this.sku,
    required this.emoji,
    required this.type,
    required this.date,
    required this.status,
  });
}

class PurchaseOrder {
  final String poNumber;
  final String supplier;
  final String expectedDate;
  final int totalItems;
  final String status; // Pending, In-Transit, Received

  const PurchaseOrder({
    required this.poNumber,
    required this.supplier,
    required this.expectedDate,
    required this.totalItems,
    required this.status,
  });
}

class OutboundOrder {
  final String orderId;
  final String destination;
  final int itemsCount;
  final String dispatchDate;
  final String status; // Processing, Shipped, Delivered

  const OutboundOrder({
    required this.orderId,
    required this.destination,
    required this.itemsCount,
    required this.dispatchDate,
    required this.status,
  });
}

class Supplier {
  final String companyName;
  final String contactPerson;
  final String email;
  final String phone;
  final int activeOrders;
  final String initials;

  const Supplier({
    required this.companyName,
    required this.contactPerson,
    required this.email,
    required this.phone,
    required this.activeOrders,
    required this.initials,
  });
}

class ReportTemplate {
  final String title;
  final String description;
  final String icon;

  const ReportTemplate({required this.title, required this.description, required this.icon});
}

class TeamMember {
  final String name;
  final String email;
  final String role; // Admin, Manager, Staff
  final String initials;

  const TeamMember({required this.name, required this.email, required this.role, required this.initials});
}
