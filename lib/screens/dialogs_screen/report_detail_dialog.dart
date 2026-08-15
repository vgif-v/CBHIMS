import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/buttons.dart';
import '../../widgets/status_badge.dart';

enum ReportType {
  inventoryValuation,
  lowStockSummary,
  transactionMovement,
}

class ReportDetailDialog extends StatefulWidget {
  final ReportType reportType;
  final String reportTitle;
  final String reportDescription;

  const ReportDetailDialog({
    super.key,
    required this.reportType,
    required this.reportTitle,
    required this.reportDescription,
  });

  static Future<void> show(
    BuildContext context, {
    required ReportType reportType,
    required String reportTitle,
    required String reportDescription,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReportDetailDialog(
        reportType: reportType,
        reportTitle: reportTitle,
        reportDescription: reportDescription,
      ),
    );
  }

  @override
  State<ReportDetailDialog> createState() => _ReportDetailDialogState();
}

class _ReportDetailDialogState extends State<ReportDetailDialog> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Product> _products = [];
  List<Transaction> _transactions = [];
  bool _loading = true;
  String? _error;

  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (widget.reportType == ReportType.transactionMovement) {
        final txns = await TransactionService.instance.getAll();
        if (!mounted) return;
        setState(() {
          _transactions = txns;
          _loading = false;
        });
      } else {
        final products = await ProductService.instance.getAll();
        if (!mounted) return;
        setState(() {
          _products = products;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  // Filter products or transactions by selected date range / status
  List<Product> get _filteredProducts {
    if (widget.reportType == ReportType.lowStockSummary) {
      return _products.where((p) => p.quantity <= 10).toList();
    }
    return _products;
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((t) {
      if (t.createdAt == null) return true;
      final d = t.createdAt!;
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
      final end =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      return d.isAfter(start.subtract(const Duration(seconds: 1))) &&
          d.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> get _computedTransactionRows {
    final sorted = List<Transaction>.from(_transactions)
      ..sort((a, b) => (a.createdAt ?? DateTime(1970))
          .compareTo(b.createdAt ?? DateTime(1970)));

    int running = 0;
    final Map<dynamic, int> balanceMap = {};
    for (int i = 0; i < sorted.length; i++) {
      final t = sorted[i];
      final isReceive = t.type.toLowerCase() == 'receive' ||
          t.type.toLowerCase() == 'inbound' ||
          t.type.toLowerCase() == 'purchase';
      if (isReceive) {
        running += t.totalItems;
      } else {
        running -= t.totalItems;
      }
      final key = t.id ?? t.billNo;
      balanceMap[key] = running;
    }

    final filtered = _filteredTransactions;
    return filtered.map((t) {
      final key = t.id ?? t.billNo;
      final bal = balanceMap[key] ?? 0;
      return {
        'transaction': t,
        'balance': bal,
      };
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // PDF Generation & Download
  // ---------------------------------------------------------------------------
  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    final dateRangeStr =
        '${_dateFormat.format(_startDate)} – ${_dateFormat.format(_endDate)}';
    final generatedAtStr =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    // Build headers and rows depending on report type
    final List<String> headers;
    final List<List<String>> dataRows;

    if (widget.reportType == ReportType.transactionMovement) {
      headers = [
        'Bill No.',
        'Type',
        'Total Items',
        'Created By',
      ];
      dataRows = _computedTransactionRows.map((row) {
        final t = row['transaction'] as Transaction;
        final dStr =
            t.createdAt != null ? _dateFormat.format(t.createdAt!) : 'N/A';
        return [
          '${t.billNo}\n$dStr',
          t.type.toUpperCase(),
          '${t.totalItems}',
          t.createdByName ?? 'User',
        ];
      }).toList();
    } else {
      headers = [
        'Product Name',
        'Quantity',
        'Unit',
        'Stock Status'
      ];
      dataRows = _filteredProducts.map((p) {
        final statusStr = p.quantity <= 0
            ? 'Out of stock'
            : (p.quantity <= 10 ? 'Low stock' : 'Healthy');
        return [
          p.productName,
          '${p.quantity}',
          p.unit,
          statusStr,
        ];
      }).toList();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Celis Brothers Hardware',
                        style: const pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red800,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Inventory Management System - Official Report',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    generatedAtStr,
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            pw.Text(widget.reportTitle,
                style: const pw.TextStyle(
                    fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Date Range: $dateRangeStr',
                style:
                    const pw.TextStyle(fontSize: 11, color: PdfColors.grey800)),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: dataRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerStyle: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 10),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${widget.reportTitle.replaceAll(" ", "_")}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // CSV Generation & Export
  // ---------------------------------------------------------------------------
  Future<void> _exportCsv() async {
    final StringBuffer csvBuffer = StringBuffer();

    // Title & Date Header
    csvBuffer.writeln('"Celis Brothers Hardware - ${widget.reportTitle}"');
    csvBuffer.writeln(
        '"Date Range: ${_dateFormat.format(_startDate)} to ${_dateFormat.format(_endDate)}"');
    csvBuffer.writeln();

    if (widget.reportType == ReportType.transactionMovement) {
      csvBuffer.writeln(
          '"Bill No.","Type","Total Items","Created By","Date"');
      for (final row in _computedTransactionRows) {
        final t = row['transaction'] as Transaction;
        final dStr =
            t.createdAt != null ? _dateFormat.format(t.createdAt!) : 'N/A';
        csvBuffer.writeln(
            '"${t.billNo}","${t.type}","${t.totalItems}","${t.createdByName ?? ''}","$dStr"');
      }
    } else {
      csvBuffer.writeln('"Product Name","Quantity","Unit","Stock Status"');
      for (final p in _filteredProducts) {
        final statusStr = p.quantity <= 0
            ? 'Out of stock'
            : (p.quantity <= 10 ? 'Low stock' : 'Healthy');
        csvBuffer.writeln(
            '"${p.productName}","${p.quantity}","${p.unit}","$statusStr"');
      }
    }

    final bytes = utf8.encode(csvBuffer.toString());
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: '${widget.reportTitle.replaceAll(" ", "_")}.csv',
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 900 ? 860.0 : width * 0.94;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 760),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBrandedHeader(),
            const Divider(height: 1, color: AppColors.border),
            _buildDateRangeSelector(),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: _buildDataPreview()),
            const Divider(height: 1, color: AppColors.border),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 20, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/images/clogo.png', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Celis Brothers Hardware',
                        style: AppTextStyles.h2.copyWith(fontSize: 20)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('OFFICIAL REPORT',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(widget.reportTitle,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 20),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      color: AppColors.background,
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('Filter Date Range:',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          _dateButton(
              label: _dateFormat.format(_startDate), onTap: _selectStartDate),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded,
              size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          _dateButton(
              label: _dateFormat.format(_endDate), onTap: _selectEndDate),
          const Spacer(),
          Text(
            widget.reportType == ReportType.transactionMovement
                ? '${_filteredTransactions.length} transactions'
                : '${_filteredProducts.length} items',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _dateButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today_rounded,
                size: 13, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPreview() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load report data', style: AppTextStyles.h3),
            const SizedBox(height: 6),
            Text(_error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.danger)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _loadReportData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (widget.reportType == ReportType.transactionMovement) {
      final rows = _computedTransactionRows;
      if (rows.isEmpty) {
        return Center(
          child: Text('No transactions found within selected date range.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Table(
          border: TableBorder.all(color: AppColors.border, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.8),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppColors.neutralSoft),
              children: [
                _TableCellHeader('BILL NO.'),
                _TableCellHeader('TYPE'),
                _TableCellHeader('ITEMS'),
                _TableCellHeader('CREATED BY'),
              ],
            ),
            ...rows.map((row) {
              final t = row['transaction'] as Transaction;
              final isInbound = t.type.toLowerCase() == 'receive' ||
                  t.type.toLowerCase() == 'inbound' ||
                  t.type.toLowerCase() == 'purchase';
              final dStr = t.createdAt != null
                  ? _dateFormat.format(t.createdAt!)
                  : 'N/A';
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.billNo,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(dStr,
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _TableCellWidget(
                    StatusBadge(
                      label: isInbound ? 'RECEIVE' : 'RELEASE',
                      tone: isInbound
                          ? BadgeTone.success
                          : BadgeTone.danger,
                    ),
                  ),
                  _TableCellText('${t.totalItems}'),
                  _TableCellText(t.createdByName ?? 'User'),
                ],
              );
            }),
          ],
        ),
      );
    } else {
      final products = _filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Text('No products match this report criteria.',
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Table(
          border: TableBorder.all(color: AppColors.border, width: 1),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: AppColors.neutralSoft),
              children: [
                _TableCellHeader('PRODUCT NAME'),
                _TableCellHeader('IN STOCK'),
                _TableCellHeader('UNIT'),
                _TableCellHeader('STOCK STATUS'),
              ],
            ),
            ...products.map((p) {
              final tone = p.quantity <= 0
                  ? BadgeTone.danger
                  : (p.quantity <= 10 ? BadgeTone.warning : BadgeTone.success);
              final statusStr = p.quantity <= 0
                  ? 'Out of stock'
                  : (p.quantity <= 10 ? 'Low stock' : 'Healthy');

              return TableRow(
                children: [
                  _TableCellText(p.productName, isBold: true),
                  _TableCellText('${p.quantity}'),
                  _TableCellText(p.unit),
                  _TableCellWidget(StatusBadge(label: statusStr, tone: tone)),
                ],
              );
            }),
          ],
        ),
      );
    }
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: Text('Close', style: AppTextStyles.bodyMedium),
          ),
          const Spacer(),
          SecondaryButton(
            label: 'Export CSV',
            icon: Icons.table_chart_outlined,
            onPressed: _exportCsv,
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            label: 'Export PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: _exportPdf,
          ),
        ],
      ),
    );
  }
}

class _TableCellHeader extends StatelessWidget {
  final String text;
  const _TableCellHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text, style: AppTextStyles.label.copyWith(fontSize: 11)),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final bool isBold;
  const _TableCellText(this.text, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: isBold ? AppTextStyles.bodyMedium : AppTextStyles.body,
      ),
    );
  }
}

class _TableCellWidget extends StatelessWidget {
  final Widget child;
  const _TableCellWidget(this.child);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }
}
