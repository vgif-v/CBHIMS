import 'transaction_item.dart';

/// A transaction that was created while offline (or that failed to reach
/// the server) and is waiting to be synced.
///
/// This stores the exact inputs [TransactionService.create] needs, so
/// syncing just means replaying that call later with the same arguments.
class PendingTransaction {
  /// Client-generated ID, stable for the life of this queue entry.
  /// Used as the Hive key and also stamped into the local bill number
  /// fallback so duplicate queue entries are easy to spot.
  final String localId;

  final String billNo;
  final String type;
  final String status;
  final List<TransactionItem> items;
  final String? remarks;
  final String? issuedTo;
  final String? userId;

  /// When this was first queued.
  final DateTime queuedAt;

  /// Set when a sync attempt fails. Null means "never tried" or "no error
  /// from the most recent attempt" — check [lastAttemptAt] to distinguish.
  final String? lastError;

  /// When the most recent sync attempt happened (success or failure).
  final DateTime? lastAttemptAt;

  const PendingTransaction({
    required this.localId,
    required this.billNo,
    required this.type,
    required this.status,
    required this.items,
    this.remarks,
    this.issuedTo,
    this.userId,
    required this.queuedAt,
    this.lastError,
    this.lastAttemptAt,
  });

  PendingTransaction copyWith({
    String? lastError,
    DateTime? lastAttemptAt,
    bool clearError = false,
  }) {
    return PendingTransaction(
      localId: localId,
      billNo: billNo,
      type: type,
      status: status,
      items: items,
      remarks: remarks,
      issuedTo: issuedTo,
      userId: userId,
      queuedAt: queuedAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }

  /// Whether the most recent sync attempt failed.
  bool get hasError => lastError != null;

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'billNo': billNo,
        'type': type,
        'status': status,
        'items': items.map((i) => i.toInsertJson(0)).toList(),
        'remarks': remarks,
        'issuedTo': issuedTo,
        'userId': userId,
        'queuedAt': queuedAt.toIso8601String(),
        'lastError': lastError,
        'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      };

  factory PendingTransaction.fromJson(Map<dynamic, dynamic> json) {
    return PendingTransaction(
      localId: json['localId'] as String,
      billNo: json['billNo'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      items: (json['items'] as List)
          .map((raw) => TransactionItem.fromJson(
              Map<String, dynamic>.from(raw as Map)))
          .toList(),
      remarks: json['remarks'] as String?,
      issuedTo: json['issuedTo'] as String?,
      userId: json['userId'] as String?,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      lastError: json['lastError'] as String?,
      lastAttemptAt: json['lastAttemptAt'] != null
          ? DateTime.parse(json['lastAttemptAt'] as String)
          : null,
    );
  }
}