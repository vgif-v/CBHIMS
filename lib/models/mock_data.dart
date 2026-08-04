import 'models.dart';

class MockData {
  MockData._();

  static const List<Product> products = [
    Product(name: 'Wireless Mouse M2', sku: 'WM-2201-BLK', category: 'Electronics', quantity: 452, reorderPoint: 100, unitPrice: 18.99, emoji: '🖱️'),
    Product(name: 'Mechanical Keyboard K6', sku: 'KB-6600-GRY', category: 'Electronics', quantity: 38, reorderPoint: 50, unitPrice: 64.50, emoji: '⌨️'),
    Product(name: 'USB-C Hub 7-in-1', sku: 'HUB-0771-SLV', category: 'Electronics', quantity: 0, reorderPoint: 40, unitPrice: 32.00, emoji: '🔌'),
    Product(name: 'Standing Desk Frame', sku: 'DSK-4410-BLK', category: 'Furniture', quantity: 120, reorderPoint: 25, unitPrice: 210.00, emoji: '🪑'),
    Product(name: 'Ergo Office Chair', sku: 'CHR-3301-GRY', category: 'Furniture', quantity: 12, reorderPoint: 15, unitPrice: 189.99, emoji: '🪑'),
    Product(name: 'A4 Copy Paper (Ream)', sku: 'PPR-1001-WHT', category: 'Office Supplies', quantity: 980, reorderPoint: 200, unitPrice: 4.25, emoji: '📄'),
    Product(name: 'Ballpoint Pen (Box)', sku: 'PEN-0090-BLU', category: 'Office Supplies', quantity: 15, reorderPoint: 60, unitPrice: 6.10, emoji: '🖊️'),
    Product(name: 'LED Desk Lamp', sku: 'LMP-2250-WHT', category: 'Electronics', quantity: 76, reorderPoint: 30, unitPrice: 27.75, emoji: '💡'),
    Product(name: 'Packing Tape Roll', sku: 'PKG-0044-CLR', category: 'Packaging', quantity: 0, reorderPoint: 100, unitPrice: 2.10, emoji: '📦'),
    Product(name: 'Shipping Box (Medium)', sku: 'PKG-0210-BRN', category: 'Packaging', quantity: 340, reorderPoint: 150, unitPrice: 1.35, emoji: '📦'),
  ];

  static const List<Transaction> transactions = [
    Transaction(itemName: 'Wireless Mouse M2', sku: 'WM-2201-BLK', emoji: '🖱️', type: TxnType.inbound, date: 'Jul 24, 2026', status: 'Completed'),
    Transaction(itemName: 'Ergo Office Chair', sku: 'CHR-3301-GRY', emoji: '🪑', type: TxnType.outbound, date: 'Jul 24, 2026', status: 'Completed'),
    Transaction(itemName: 'Standing Desk Frame', sku: 'DSK-4410-BLK', emoji: '🪑', type: TxnType.outbound, date: 'Jul 23, 2026', status: 'Completed'),
    Transaction(itemName: 'USB-C Hub 7-in-1', sku: 'HUB-0771-SLV', emoji: '🔌', type: TxnType.inbound, date: 'Jul 23, 2026', status: 'Processing'),
    Transaction(itemName: 'A4 Copy Paper (Ream)', sku: 'PPR-1001-WHT', emoji: '📄', type: TxnType.inbound, date: 'Jul 22, 2026', status: 'Completed'),
    Transaction(itemName: 'LED Desk Lamp', sku: 'LMP-2250-WHT', emoji: '💡', type: TxnType.outbound, date: 'Jul 22, 2026', status: 'Completed'),
  ];

  static const List<PurchaseOrder> purchaseOrders = [
    PurchaseOrder(poNumber: 'PO-10234', supplier: 'Nordic Supply Co.', expectedDate: 'Jul 28, 2026', totalItems: 320, status: 'In-Transit'),
    PurchaseOrder(poNumber: 'PO-10233', supplier: 'Pacific Office Goods', expectedDate: 'Jul 26, 2026', totalItems: 150, status: 'Pending'),
    PurchaseOrder(poNumber: 'PO-10229', supplier: 'Summit Electronics Ltd.', expectedDate: 'Jul 20, 2026', totalItems: 500, status: 'Received'),
    PurchaseOrder(poNumber: 'PO-10225', supplier: 'Nordic Supply Co.', expectedDate: 'Jul 18, 2026', totalItems: 90, status: 'Received'),
    PurchaseOrder(poNumber: 'PO-10221', supplier: 'Cascade Furnishings', expectedDate: 'Aug 02, 2026', totalItems: 40, status: 'Pending'),
  ];

  static const List<OutboundOrder> outboundOrders = [
    OutboundOrder(orderId: 'SO-88031', destination: 'Meridian Retail Group', itemsCount: 24, dispatchDate: 'Jul 25, 2026', status: 'Processing'),
    OutboundOrder(orderId: 'SO-88028', destination: 'Northgate Distributors', itemsCount: 12, dispatchDate: 'Jul 24, 2026', status: 'Shipped'),
    OutboundOrder(orderId: 'SO-88019', destination: 'Bluepeak Logistics', itemsCount: 60, dispatchDate: 'Jul 22, 2026', status: 'Delivered'),
    OutboundOrder(orderId: 'SO-88015', destination: 'Harbor & Co. Retail', itemsCount: 8, dispatchDate: 'Jul 21, 2026', status: 'Delivered'),
    OutboundOrder(orderId: 'SO-88011', destination: 'Meridian Retail Group', itemsCount: 33, dispatchDate: 'Jul 19, 2026', status: 'Delivered'),
  ];

  static const List<ReportTemplate> reportTemplates = [
    ReportTemplate(title: 'Inventory Valuation Report', description: 'Current stock value by category and location.', icon: '💰'),
    ReportTemplate(title: 'Low Stock Summary', description: 'Items at or below their reorder point.', icon: '⚠️'),
    ReportTemplate(title: 'Dead Stock Analysis', description: 'Products with no movement in 90+ days.', icon: '📉'),
  ];

  static const List<TeamMember> team = [
    TeamMember(name: 'Ava Thompson', email: 'ava@yourcompany.com', role: 'Admin', initials: 'AT'),
    TeamMember(name: 'Liam Chen', email: 'liam@yourcompany.com', role: 'Manager', initials: 'LC'),
    TeamMember(name: 'Sara Delgado', email: 'sara@yourcompany.com', role: 'Manager', initials: 'SD'),
    TeamMember(name: 'Noah Patel', email: 'noah@yourcompany.com', role: 'Staff', initials: 'NP'),
    TeamMember(name: 'Grace Kim', email: 'grace@yourcompany.com', role: 'Staff', initials: 'GK'),
  ];
}
