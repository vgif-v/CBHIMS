import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../models/transaction_item.dart';
import 'product_service.dart';
import 'package:uuid/uuid.dart';
import '../models/pending_transaction.dart';
import 'offline_queue_service.dart';

List<String>? _billNoCache;

bool _looksLikeConnectivityError(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('socketexception') ||
      s.contains('clientexception') ||
      s.contains('failed host lookup') ||
      s.contains('connection refused') ||
      s.contains('connection closed') ||
      s.contains('network is unreachable') ||
      s.contains('timeoutexception') ||
      s.contains('no internet');
}

/// Fetch distinct bill numbers across ALL transactions (all users), for
/// autocomplete. Cached in-memory after first successful fetch; call
/// refreshBillNoCache() if you need to force a re-fetch (e.g. after
/// creating a transaction with a brand-new bill number).
Future<List<String>> getAllBillNumbers() async {
  if (_billNoCache != null) return _billNoCache!;
  try {
    final rows =
        await Supabase.instance.client.from('transactions').select('bill_no');
    final seen = <String>{};
    for (final row in (rows as List)) {
      final billNo = (row as Map)['bill_no']?.toString().trim();
      if (billNo != null && billNo.isNotEmpty) seen.add(billNo);
    }
    _billNoCache = seen.toList()..sort();
    return _billNoCache!;
  } catch (e) {
    debugPrint('[TransactionService] Failed to load bill numbers: $e');
    return _billNoCache ?? [];
  }
}

/// Call after creating a transaction so the next autocomplete includes
/// the bill number that was just used.
void refreshBillNoCache() => _billNoCache = null;

/// Thrown when an outbound transaction requests more of one or more
/// products than are currently in stock. Carries enough detail for the
/// UI to show a specific "X: requested 150, only 100 in stock" message.
class InsufficientStockError implements Exception {
  final List<StockShortfall> shortfalls;
  InsufficientStockError(this.shortfalls);

  @override
  String toString() => 'InsufficientStockError: '
      '${shortfalls.map((s) => '${s.productId} (requested ${s.requested}, have ${s.available})').join(', ')}';
}

class StockShortfall {
  final int productId;
  final String? productName;
  final int requested;
  final int available;
  StockShortfall({
    required this.productId,
    required this.available,
    required this.requested,
    this.productName,
  });
}

/// Service for all transaction-related Supabase operations.
class TransactionService {
  TransactionService._();
  static final TransactionService instance = TransactionService._();

  final SupabaseClient _client = Supabase.instance.client;

  /// Map of userId -> fullName cache to avoid repeated queries.
  final Map<String, String> _userNameCache = {};

  /// Map of productId -> productName cache.
  final Map<int, String> _productNameCache = {};

  Future<String?> _getUserName(String? userId) async {
    if (userId == null || userId.isEmpty) return null;
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId];

    try {
      final res = await _client
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && res['full_name'] != null) {
        final name = res['full_name'] as String;
        _userNameCache[userId] = name;
        return name;
      }
    } catch (e) {
      debugPrint('[TransactionService] Could not resolve user name: $e');
    }
    return null;
  }

  /// Preload all active product names into cache.
  Future<void> _preloadProductNames() async {
    try {
      final rows = await _client.from('products').select('id, product_name');
      for (final row in (rows as List)) {
        final map = row as Map;
        final id = map['id'] is int
            ? map['id'] as int
            : int.tryParse(map['id']?.toString() ?? '');
        final name = map['product_name']?.toString();
        if (id != null && name != null && name.trim().isNotEmpty) {
          _productNameCache[id] = name.trim();
        }
      }
    } catch (e) {
      debugPrint('[TransactionService] Could not preload product names: $e');
    }
  }

  /// Attach items to a list of transaction rows and resolve product names + user names.
  Future<List<Transaction>> _buildTransactionList(List responseList) async {
    final transactions = <Transaction>[];

    final ids = <int>[];
    for (final row in responseList) {
      if (row is Map && row['id'] != null) {
        final id = row['id'] is int
            ? row['id'] as int
            : int.tryParse(row['id'].toString());
        if (id != null) ids.add(id);
      }
    }

    Map<int, List<Map<String, dynamic>>> itemsByTxnId = {};
    if (ids.isNotEmpty) {
      try {
        await _preloadProductNames();
        final itemsRows = await _client.from('transaction_items').select('*');

        for (final row in (itemsRows as List)) {
          final itemMap = Map<String, dynamic>.from(row as Map);
          final txnId = itemMap['transaction_id'] is int
              ? itemMap['transaction_id'] as int
              : int.tryParse(itemMap['transaction_id']?.toString() ?? '');
          if (txnId != null) {
            final pid = itemMap['product_id'] is int
                ? itemMap['product_id'] as int
                : int.tryParse(itemMap['product_id']?.toString() ?? '');

            String? name = itemMap['product_name']?.toString().trim();
            if (name == null || name.isEmpty) {
              if (pid != null && _productNameCache.containsKey(pid)) {
                name = _productNameCache[pid];
              }
            }
            itemMap['product_name'] = (name != null && name.isNotEmpty)
                ? name
                : (pid != null ? 'Product #$pid' : 'Item');

            itemsByTxnId.putIfAbsent(txnId, () => []).add(itemMap);
          }
        }
      } catch (e) {
        debugPrint(
            '[TransactionService] Bulk load transaction_items failed: $e');
      }
    }

    for (final row in responseList) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id'] is int
          ? map['id'] as int
          : int.tryParse(map['id']?.toString() ?? '');
      if (id != null && itemsByTxnId.containsKey(id)) {
        map['transaction_items'] = itemsByTxnId[id];
      }

      final createdBy = map['created_by'] as String?;
      final userName = await _getUserName(createdBy);
      if (userName != null) {
        map['users'] = {'full_name': userName};
      }
      transactions.add(Transaction.fromJson(map));
    }

    return transactions;
  }

  /// Fetch all transactions, ordered by most recent.
  Future<List<Transaction>> getAll() async {
    final response = await _client
        .from('transactions')
        .select('*')
        .order('created_at', ascending: false);

    return _buildTransactionList(response as List);
  }

  /// Fetch all transactions associated with a specific product ID,
  /// ordered by created_at ascending (oldest first) so running stock balances
  /// can be calculated chronologically in the product ledger.
  Future<List<Transaction>> getByProductId(int productId) async {
    final itemsRows = await _client
        .from('transaction_items')
        .select('*')
        .eq('product_id', productId);

    final list = itemsRows as List;
    if (list.isEmpty) return [];

    final txnIds = <int>{};
    for (final row in list) {
      final txnId = row['transaction_id'] is int
          ? row['transaction_id'] as int
          : int.tryParse(row['transaction_id']?.toString() ?? '');
      if (txnId != null) txnIds.add(txnId);
    }

    if (txnIds.isEmpty) return [];

    final response = await _client
        .from('transactions')
        .select('*')
        .inFilter('id', txnIds.toList())
        .order('created_at', ascending: true);

    return _buildTransactionList(response as List);
  }

  /// Fetch a single transaction with its items.
  Future<Transaction> getById(int id) async {
    final txnRow =
        await _client.from('transactions').select('*').eq('id', id).single();
    final map = Map<String, dynamic>.from(txnRow);

    try {
      await _preloadProductNames();
      final itemsRow = await _client
          .from('transaction_items')
          .select('*')
          .eq('transaction_id', id);

      final itemsList = <Map<String, dynamic>>[];

      for (final row in (itemsRow as List)) {
        final itemMap = Map<String, dynamic>.from(row as Map);
        final pid = itemMap['product_id'] is int
            ? itemMap['product_id'] as int
            : int.tryParse(itemMap['product_id']?.toString() ?? '');

        String? name = itemMap['product_name']?.toString().trim();
        if (name == null || name.isEmpty) {
          if (pid != null && _productNameCache.containsKey(pid)) {
            name = _productNameCache[pid];
          }
        }
        itemMap['product_name'] = (name != null && name.isNotEmpty)
            ? name
            : (pid != null ? 'Product #$pid' : 'Item');

        itemsList.add(itemMap);
      }

      map['transaction_items'] = itemsList;
    } catch (e) {
      debugPrint('[TransactionService] Failed to load transaction_items: $e');
    }

    // Resolve user name
    final createdBy = map['created_by'] as String?;
    final userName = await _getUserName(createdBy);
    if (userName != null) {
      map['users'] = {'full_name': userName};
    }

    return Transaction.fromJson(map);
  }

  /// Fetch the most recent transactions (for the dashboard).
  Future<List<Transaction>> getRecent({int limit = 5}) async {
    final response = await _client
        .from('transactions')
        .select('*')
        .order('created_at', ascending: false)
        .limit(limit);

    return _buildTransactionList(response as List);
  }

  /// Checks requested outbound quantities against current stock BEFORE
  /// any transaction/item rows are created. Returns the list of
  /// shortfalls (empty if everything is available). This is a courtesy
  /// pre-check for a fast, specific UI error message — the real
  /// enforcement happens atomically in ProductService.updateQuantity via
  /// adjust_product_quantity(), which is race-safe; this check alone is
  /// not (two concurrent submissions could both pass it).
  Future<List<StockShortfall>> _checkStockAvailability(
      List<TransactionItem> items) async {
    final shortfalls = <StockShortfall>[];
    final productService = ProductService.instance;

    for (final item in items) {
      if (item.productId == null) continue;
      try {
        final available =
            await productService.getCurrentQuantity(item.productId!);
        if (item.quantity > available) {
          shortfalls.add(StockShortfall(
            productId: item.productId!,
            productName: _productNameCache[item.productId!],
            requested: item.quantity,
            available: available,
          ));
        }
      } catch (e) {
        debugPrint(
            '[TransactionService] Stock pre-check failed for product ${item.productId}: $e');
        // Don't block the transaction on a pre-check failure — the
        // atomic DB-side check in updateQuantity is the real guard.
      }
    }
    return shortfalls;
  }

  /// Create a new transaction. If the device is offline (or the request
  /// fails for a connectivity reason), the transaction is queued locally
  /// instead of thrown away, and a locally-flagged Transaction is returned
  /// so the UI can show it immediately as "Pending Sync".
  ///
  /// For outbound transactions, throws [InsufficientStockError] if any
  /// item requests more than is currently in stock — no transaction or
  /// item rows are created in that case.
  ///
  /// Non-connectivity errors (e.g. a genuine server-side validation
  /// failure) are NOT queued — they're rethrown as before, since retrying
  /// them later would just fail the same way.
  Future<Transaction> create({
    required String billNo,
    required String type,
    String status = 'Completed',
    required List<TransactionItem> items,
    String? remarks,
    String? issuedTo,
    String? userId,
  }) async {
    // Pre-flight stock check for outbound transactions. This happens
    // BEFORE any row is written, so a rejected request leaves no trace
    // (no orphaned transaction/item rows to clean up).
    if (type.toLowerCase() == 'release') {
      final shortfalls = await _checkStockAvailability(items);
      if (shortfalls.isNotEmpty) throw InsufficientStockError(shortfalls);
    }

    try {
      return await _createRemote(
        billNo: billNo,
        type: type,
        status: status,
        items: items,
        remarks: remarks,
        issuedTo: issuedTo,
        userId: userId,
      );
    } catch (e) {
      if (e is InsufficientStockError) rethrow;
      if (!_looksLikeConnectivityError(e)) rethrow;

      debugPrint(
          '[TransactionService] create() failed due to connectivity, queuing offline: $e');

      final localId = const Uuid().v4();
      final pending = PendingTransaction(
        localId: localId,
        billNo: billNo,
        type: type,
        status: status,
        items: items,
        remarks: remarks,
        issuedTo: issuedTo,
        userId: userId,
        queuedAt: DateTime.now(),
      );
      await OfflineQueueService.instance.enqueue(pending);

      return Transaction(
        id: null,
        billNo: billNo,
        type: type,
        totalItems: items.fold<int>(0, (sum, item) => sum + item.quantity),
        remarks: (remarks != null && remarks.trim().isNotEmpty)
            ? remarks.trim()
            : 'N/A',
        createdBy: userId,
        createdByName: null,
        createdAt: DateTime.now(),
        items: items,
        localId: localId,
        isPendingSync: true,
      );
    }
  }

  /// Create a new transaction with items, and update product quantities.
  Future<Transaction> _createRemote({
    required String billNo,
    required String type,
    String status = 'Completed',
    required List<TransactionItem> items,
    String? remarks,
    String? issuedTo,
    String? userId,
  }) async {
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);

    final String finalIssuedTo =
        (issuedTo != null && issuedTo.trim().isNotEmpty)
            ? issuedTo.trim()
            : 'N/A';
    final String finalRemarks =
        (remarks != null && remarks.trim().isNotEmpty) ? remarks.trim() : 'N/A';

    // bill_no is intentionally NOT unique (repeat customers reuse their own
    // bill numbers on later, unrelated visits) — so it must never be used
    // to look up "the row I just inserted." Only txnResponse['id'] from the
    // insert's own .select() can safely identify that row.
    final String currentBillNo = billNo;
    Map<String, dynamic>? txnResponse;

    final statusLower = status.toLowerCase();
    final statusCapital = status.length > 1
        ? status[0].toUpperCase() + status.substring(1).toLowerCase()
        : status;

    final typeTitle = type.isNotEmpty
        ? (type[0].toUpperCase() + type.substring(1).toLowerCase())
        : type;
    final typeLower = type.toLowerCase();

    Map<String, dynamic> buildPayload({
      String? statusVal,
      required String typeVal,
      required bool includeCreatedBy,
      bool includeIssuedTo = true,
    }) {
      final map = <String, dynamic>{
        'bill_no': currentBillNo,
        'type': typeVal,
        'total_items': totalItems,
        'remarks': finalRemarks,
      };
      if (statusVal != null) map['status'] = statusVal;
      if (includeIssuedTo) map['issued_to'] = finalIssuedTo;
      if (includeCreatedBy && userId != null && userId.isNotEmpty) {
        map['created_by'] = userId;
      }
      return map;
    }

    final payloadsToTry = [
      buildPayload(
          statusVal: statusCapital, typeVal: typeTitle, includeCreatedBy: true),
      buildPayload(
          statusVal: statusCapital,
          typeVal: typeTitle,
          includeCreatedBy: false),
      buildPayload(
          statusVal: statusLower, typeVal: typeLower, includeCreatedBy: true),
      buildPayload(
          statusVal: statusLower, typeVal: typeLower, includeCreatedBy: false),
      buildPayload(
          statusVal: statusCapital, typeVal: typeLower, includeCreatedBy: true),
      buildPayload(
          statusVal: statusCapital,
          typeVal: typeLower,
          includeCreatedBy: false),
      buildPayload(
          statusVal: statusLower, typeVal: typeTitle, includeCreatedBy: true),
      buildPayload(
          statusVal: null, typeVal: typeTitle, includeCreatedBy: false),
      buildPayload(
          statusVal: null, typeVal: typeLower, includeCreatedBy: false),
    ];

    for (int i = 0; i < payloadsToTry.length; i++) {
      try {
        final payload = payloadsToTry[i];
        final res = await _client
            .from('transactions')
            .insert(payload)
            .select()
            .maybeSingle();

        if (res != null) {
          txnResponse = Map<String, dynamic>.from(res);
          break;
        }

        // .select() returned null after a successful insert — this means
        // the insert went through but the current role can't SELECT it
        // back (an RLS gap), not that it failed. We deliberately do NOT
        // try to recover the row by bill_no anymore, since bill_no is no
        // longer unique and could match an unrelated older transaction.
        // Log it and move on — txnId will be filled in as null below, and
        // the function still returns a usable in-memory Transaction.
        debugPrint('[TransactionService] Insert attempt ${i + 1} succeeded but '
            '.select() returned null (likely an RLS SELECT gap for this '
            'role). Not attempting bill_no lookup since bill_no is not '
            'unique. Consider fixing the SELECT policy on transactions.');
        break;
      } catch (e) {
        debugPrint('[TransactionService] Insert attempt ${i + 1} failed: $e');
        if (i == payloadsToTry.length - 1) {
          rethrow;
        }
        // No more duplicate-key retry branch — bill_no collisions are
        // expected and valid now, not errors to work around.
      }
    }

    int? txnId;
    if (txnResponse != null && txnResponse['id'] != null) {
      txnId = txnResponse['id'] is int
          ? txnResponse['id'] as int
          : int.tryParse(txnResponse['id'].toString());
    }
    // NOTE: the old "if (txnId == null) { look up by bill_no }" fallback
    // has been removed entirely. With bill_no no longer unique, that
    // lookup could silently attach items to a different, older transaction
    // that happens to share the same bill number — a correctness bug, not
    // just a missing feature. If txnId is null here, it means the insert's
    // .select() didn't return the row (RLS gap, see above) — items simply
    // can't be safely inserted in that case, and the fix is on the RLS
    // policy, not a client-side workaround.

    bool itemsSaved = false;
    if (txnId != null && items.isNotEmpty) {
      try {
        final itemRows =
            items.map((item) => item.toInsertJson(txnId!)).toList();
        await _client.from('transaction_items').insert(itemRows);
        itemsSaved = true;
      } catch (e) {
        debugPrint(
            '[TransactionService] Standard transaction_items insert failed: $e. Trying fallback without unit.');
      }

      if (!itemsSaved) {
        try {
          final fallbackRows = items
              .map((item) => {
                    'transaction_id': txnId,
                    'product_id': item.productId,
                    'product_name': item.productName,
                    'quantity': item.quantity,
                  })
              .toList();
          await _client.from('transaction_items').insert(fallbackRows);
          itemsSaved = true;
        } catch (e2) {
          debugPrint(
              '[TransactionService] Fallback 1 failed: $e2. Trying minimal items insert.');
        }
      }

      if (!itemsSaved) {
        try {
          final minimalRows = items
              .map((item) => {
                    'transaction_id': txnId,
                    'product_id': item.productId,
                    'quantity': item.quantity,
                  })
              .toList();
          await _client.from('transaction_items').insert(minimalRows);
          itemsSaved = true;
        } catch (e3) {
          debugPrint(
              '[TransactionService] Minimal transaction_items insert failed: $e3');
          rethrow;
        }
      }
    } else if (txnId == null && items.isNotEmpty) {
      // We have items to save but no confirmed transaction id — surface
      // this loudly rather than silently dropping the items.
      debugPrint('[TransactionService] WARNING: transaction was created but '
          'txnId is unknown (RLS SELECT gap) — transaction_items were NOT '
          'inserted. Fix the SELECT policy on the transactions table.');
    }

    final productService = ProductService.instance;
    for (final item in items) {
      if (item.productId != null) {
        final quantityChange = (type.toLowerCase() == 'receive' ||
                type.toLowerCase() == 'inbound' ||
                type.toLowerCase() == 'purchase')
            ? item.quantity
            : -item.quantity;
        await productService.updateQuantity(item.productId!, quantityChange);
      }
    }

    String? createdByName;
    if (userId != null && userId.isNotEmpty) {
      createdByName = await _getUserName(userId);
    }

    final baseTxn = txnResponse != null
        ? Transaction.fromJson(txnResponse)
        : Transaction(
            billNo: currentBillNo,
            type: type,
            totalItems: totalItems,
            remarks: finalRemarks,
            createdAt: DateTime.now(),
          );

    return Transaction(
      id: baseTxn.id ?? txnId,
      billNo: baseTxn.billNo,
      type: baseTxn.type,
      totalItems: baseTxn.totalItems > 0 ? baseTxn.totalItems : totalItems,
      remarks: baseTxn.remarks,
      createdBy: userId ?? baseTxn.createdBy,
      createdByName: createdByName ?? baseTxn.createdByName,
      createdAt: baseTxn.createdAt ?? DateTime.now(),
      items: items,
    );
  }

  /// Update an existing transaction's core fields and replace its items.
  ///
  /// If [status] is 'Cancelled' (case-insensitive) and the transaction was
  /// NOT already cancelled, this automatically reverses the stock impact
  /// of the transaction's ORIGINAL items (before this edit's item changes)
  /// exactly once. If the transaction was already cancelled, status stays
  /// cancelled and stock is not touched again (prevents double-reversal).
  ///
  /// Editing a non-cancelled transaction's items/other fields (without
  /// changing status to Cancelled) does NOT touch product stock.
  Future<Transaction> update({
    required int transactionId,
    required String billNo,
    required String type,
    required List<TransactionItem> items,
    String? remarks,
    String? issuedTo,
  }) async {
    // Fetch current state first so we know whether this is a fresh
    // transition into Cancelled, and so we reverse the CORRECT (original)
    // items/quantities rather than whatever the edit form now contains.

    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);

    final String finalIssuedTo =
        (issuedTo != null && issuedTo.trim().isNotEmpty)
            ? issuedTo.trim()
            : 'N/A';
    final String finalRemarks =
        (remarks != null && remarks.trim().isNotEmpty) ? remarks.trim() : 'N/A';

    await _client.from('transactions').update({
      'bill_no': billNo,
      'type': type,
      'total_items': totalItems,
      'issued_to': finalIssuedTo,
      'remarks': finalRemarks,
    }).eq('id', transactionId);

    // Replace items: delete existing, insert new.
    //
    // IMPORTANT: we verify the delete actually removed rows before
    // inserting. Postgres does not error on a DELETE that matches 0 rows
    // (e.g. because RLS silently filtered them out for this user's role)
    // — it just succeeds having done nothing. Without this check, a
    // blocked delete followed by a successful insert produces duplicated
    // items: the old rows stay, and the new rows are added on top. This
    // is exactly what happened when transaction_items' DELETE policy was
    // more restrictive than its INSERT policy for non-admin roles.
    try {
      // Find out how many items currently exist for this transaction, so
      // we know what we EXPECT the delete to remove.
      final existingItems = await _client
          .from('transaction_items')
          .select('id')
          .eq('transaction_id', transactionId);
      final expectedDeleteCount = (existingItems as List).length;

      // .select() after .delete() returns the rows that were actually
      // deleted, so we can confirm the delete really happened rather than
      // silently matching 0 rows.
      final deletedRows = await _client
          .from('transaction_items')
          .delete()
          .eq('transaction_id', transactionId)
          .select('id');
      final actualDeleteCount = (deletedRows as List).length;

      if (expectedDeleteCount > 0 && actualDeleteCount < expectedDeleteCount) {
        // The delete didn't remove everything it should have — almost
        // certainly an RLS policy silently blocking rows for this user's
        // role. Refuse to insert on top of stale data; surface a clear
        // error instead of corrupting the transaction with duplicates.
        throw StateError(
            'Could not update items: expected to remove $expectedDeleteCount '
            'existing item(s) but only $actualDeleteCount were removed. '
            'This usually means you don\'t have permission to edit this '
            'transaction\'s items. No changes were saved.');
      }

      if (items.isNotEmpty) {
        final itemRows =
            items.map((item) => item.toInsertJson(transactionId)).toList();
        await _client.from('transaction_items').insert(itemRows);
      }
    } catch (e) {
      debugPrint(
          '[TransactionService] Failed to replace transaction_items: $e');
      rethrow;
    }

    return getById(transactionId);
  }

  /// Permanently delete a transaction and its items.
  ///
  /// Does NOT reverse stock automatically — if the transaction was still
  /// active (not cancelled), its stock impact remains applied to products
  /// unless the caller cancels it first. Callers should generally require
  /// confirmation before calling this, since it cannot be undone.
  Future<void> deleteTransaction(int transactionId) async {
    try {
      await _client
          .from('transaction_items')
          .delete()
          .eq('transaction_id', transactionId);
    } catch (e) {
      debugPrint('[TransactionService] Failed to delete transaction_items: $e');
      rethrow;
    }

    await _client.from('transactions').delete().eq('id', transactionId);
  }
}
