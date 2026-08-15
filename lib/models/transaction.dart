import 'transaction_item.dart';

class Transaction {
  final int? id;
  final String billNo;
  final String type; // 'Receive' or 'Release'
  final int totalItems;
  final String? remarks;
  final String? createdBy; // UUID of the user
  final String? createdByName; // joined from users table
  final DateTime? createdAt;
  final List<TransactionItem> items;

  /// Set only for transactions that were queued while offline. This is
  /// the Hive key in OfflineQueueService, letting the UI look the record
  /// up in the queue (e.g. to show a "retry" action) even though it has
  /// no server [id] yet.
  final String? localId;

  /// True until this transaction is confirmed to have reached Supabase.
  /// Always false for anything loaded via [fromJson], since a row that
  /// came back from the server is by definition already synced.
  final bool isPendingSync;

  const Transaction({
    this.id,
    required this.billNo,
    required this.type,
    this.totalItems = 0,
    this.remarks,
    this.createdBy,
    this.createdByName,
    this.createdAt,
    this.items = const [],
    this.localId,
    this.isPendingSync = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Handle joined users(full_name)
    String? userName;
    if (json['users'] != null && json['users'] is Map) {
      userName = json['users']['full_name'] as String?;
    }

    // Handle joined transaction_items if present
    List<TransactionItem> txnItems = [];
    if (json['transaction_items'] != null && json['transaction_items'] is List) {
      txnItems = (json['transaction_items'] as List)
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    DateTime? parsedDate;
    if (json['created_at'] != null) {
      if (json['created_at'] is String) {
        parsedDate = DateTime.tryParse(json['created_at'] as String);
      } else if (json['created_at'] is DateTime) {
        parsedDate = json['created_at'] as DateTime;
      }
    }

    int parsedTotalItems = 0;
    if (json['total_items'] != null) {
      if (json['total_items'] is int) {
        parsedTotalItems = json['total_items'] as int;
      } else if (json['total_items'] is num) {
        parsedTotalItems = (json['total_items'] as num).toInt();
      } else {
        parsedTotalItems = int.tryParse(json['total_items'].toString()) ?? 0;
      }
    }

    return Transaction(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      billNo: json['bill_no']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Receive',
      totalItems: parsedTotalItems,
      remarks: json['remarks']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdByName: userName,
      createdAt: parsedDate,
      items: txnItems,
      // Anything built from a server response is, by definition, synced.
      localId: null,
      isPendingSync: false,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'bill_no': billNo,
      'type': type,
      'status': 'Completed',
      'total_items': totalItems,
      if (remarks != null && remarks!.isNotEmpty) 'remarks': remarks,
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}