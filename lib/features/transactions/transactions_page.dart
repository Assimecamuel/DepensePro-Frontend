import 'package:flutter/material.dart';

import '../../core/api_service.dart';
import '../../core/app_settings.dart';
import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../core/pdf_service.dart';
import '../../core/responsive.dart';
import '../../widgets/app_widgets.dart';
import 'transaction_form.dart';

class TransactionsPage extends StatefulWidget {
  /// Ouvre directement le formulaire de création (raccourci depuis d'autres écrans).
  final bool openCreateOnStart;
  const TransactionsPage({super.key, this.openCreateOnStart = false});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List items = [], categories = [];
  bool loading = true;
  bool exportingPdf = false;
  String? error;
  String kind = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    load();
    if (widget.openCreateOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => openForm());
    }
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final results = await ApiService.instance.get(
        'transactions/',
        query: {if (kind.isNotEmpty) 'kind': kind},
      );
      final cats = await ApiService.instance.get('categories/');
      if (mounted) {
        setState(() {
          items = extractList(results);
          categories = extractList(cats);
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openForm({Map<String, dynamic>? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.pal.surface,
        surfaceTintColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: TransactionForm(existing: existing, categories: categories),
        ),
      ),
    );
    if (saved == true) load();
  }

  Future<void> remove(dynamic id) async {
    final confirmed = await confirmDialog(
      context,
      title: context.t('tx_delete_t'),
      message: context.t('tx_delete_m'),
    );
    if (!confirmed) return;
    try {
      await ApiService.instance.delete('transactions/$id/');
      await load();
    } catch (e) {
      if (mounted) showMessage(context, e.toString());
    }
  }

  Future<void> _exportPdf() async {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      showMessage(context, 'Aucune transaction à exporter.');
      return;
    }
    setState(() => exportingPdf = true);
    try {
      final bytes = await PdfService.instance.generateTransactionsPdf(
        transactions: filtered,
        title: 'Relevé des Transactions DepensePro',
        periodText: kind.isEmpty ? 'Toutes les catégories' : (kind == 'expense' ? 'Dépenses uniquement' : 'Revenus uniquement'),
      );
      if (mounted) {
        await PdfService.instance.shareOrPrintPdf(
          pdfBytes: bytes,
          fileName: 'Transactions_DepensePro.pdf',
          context: context,
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, 'Erreur de génération PDF : $e');
    } finally {
      if (mounted) setState(() => exportingPdf = false);
    }
  }

  List get _filtered {
    if (searchQuery.isEmpty) return items;
    final q = searchQuery.toLowerCase();
    return items.where((raw) {
      final t = Map<String, dynamic>.from(raw);
      final desc = t['description']?.toString().toLowerCase() ?? '';
      final cat = t['category_name']?.toString().toLowerCase() ?? '';
      return desc.contains(q) || cat.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    final filtered = _filtered;

    Widget body;
    if (loading && items.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null && items.isEmpty) {
      body = ErrorState(message: error!, onRetry: load);
    } else {
      body = RefreshIndicator(
        onRefresh: load,
        child: filtered.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 40),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: context.t('tx_empty_t'),
                    message: context.t('tx_empty_d'),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 96),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _TransactionTile(
                  transaction: Map<String, dynamic>.from(filtered[i]),
                  onEdit: (t) => openForm(existing: t),
                  onDelete: remove,
                ),
              ),
      );
    }

    return AppPage(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('tx_new')),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(
                        hintText: context.t('tx_search'),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final option in [
                                  ('', context.t('all')),
                                  ('expense', context.t('expenses')),
                                  ('income', context.t('incomes')),
                                ]) ...[
                                  ChoiceChip(
                                    label: Text(option.$2),
                                    selected: kind == option.$1,
                                    onSelected: (_) {
                                      setState(() => kind = option.$1);
                                      load();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: exportingPdf ? null : _exportPdf,
                          icon: exportingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(Icons.picture_as_pdf_rounded, size: 18, color: context.pal.expense),
                          label: const Text('PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<dynamic> onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = transaction;
    final income = t['kind'] == 'income';
    final hasDescription = t['description']?.toString().isNotEmpty == true;
    final title = hasDescription
        ? t['description'].toString()
        : (t['category_name']?.toString() ?? context.t('tx_new'));
    final subtitle = [
      t['category_name'] ?? '',
      context.date(t['date']),
      paymentLabel(context, t['payment_method']),
    ].where((s) => s.toString().isNotEmpty).join(' · ');
    final amount = '${income ? '+' : '−'}${context.money(t['amount'])}';
    final amountColor = income ? p.income : p.title;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => onEdit(t),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 520;
          final amountText = Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: amountColor,
            ),
          );
          return Row(
            children: [
              IconBadge(
                icon: income ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: income ? p.income : p.expense,
                background: income ? p.incomeSoft : p.expenseSoft,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: p.title,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.35),
                    ),
                    if (!wide) ...[const SizedBox(height: 4), amountText],
                  ],
                ),
              ),
              if (wide) ...[const SizedBox(width: 12), amountText],
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: p.muted),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit(t);
                  } else {
                    onDelete(t['id']);
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'edit', child: Text(ctx.t('edit'))),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(ctx.t('delete'), style: TextStyle(color: ctx.pal.expense)),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
