import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/finance_models.dart';
import '../state/finance_store.dart';
import '../widgets/common.dart';
import 'add_expense_screen.dart';
import 'transaction_tile.dart';
import 'transaction_filters.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, required this.store});
  final FinanceStore store;
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  PaymentMethod? method;
  String? category;
  String? cardId;
  DateTimeRange? period;

  final _scrollController = ScrollController();
  static const _pageSize = 20;

  List<TransactionItem> _items = [];
  int _totalCount = 0;
  int _totalAmount = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
    widget.store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    // Reload from start when store changes (e.g. expense deleted/added)
    _loadInitial();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await widget.store.getTransactions(
        TransactionFilter(
          method: method,
          category: _builtInCategory,
          customCategoryId: _customCategoryId,
          cardId: cardId,
          period: period,
          offset: 0,
          limit: _pageSize,
        ),
      );
      if (mounted) {
        setState(() {
          _items = page.items;
          _totalCount = page.totalCount;
          _totalAmount = page.totalAmount;
          _hasMore = page.items.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل البيانات';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final page = await widget.store.getTransactions(
        TransactionFilter(
          method: method,
          category: _builtInCategory,
          customCategoryId: _customCategoryId,
          cardId: cardId,
          period: period,
          offset: _items.length,
          limit: _pageSize,
        ),
      );
      if (mounted) {
        setState(() {
          _items.addAll(page.items);
          _hasMore = page.items.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'تعذر تحميل المزيد من البيانات';
          _isLoading = false;
        });
      }
    }
  }

  void _updateFilter(VoidCallback update) {
    setState(update);
    _loadInitial();
  }

  ExpenseCategory? get _builtInCategory {
    if (category == null) return null;
    return ExpenseCategory.values
        .where((item) => item.name == category)
        .firstOrNull;
  }

  String? get _customCategoryId => _builtInCategory == null ? category : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('كل المصروفات'.tr(context, 'All expenses'))),
    body: Column(
      children: [
        TransactionFilters(
          store: widget.store,
          method: method,
          category: category,
          cardId: cardId,
          period: period,
          onMethodChanged: (v) => _updateFilter(() {
            method = v;
            if (v == PaymentMethod.cash) cardId = null;
          }),
          onCategoryChanged: (v) => _updateFilter(() => category = v),
          onCardIdChanged: (v) => _updateFilter(() => cardId = v),
          onPeriodChanged: (v) => _updateFilter(() => period = v),
          onClear: () => _updateFilter(() {
            method = null;
            category = null;
            cardId = null;
            period = null;
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'إجمالي النتائج'.tr(context, 'Results total'),
                  value: money(context, _totalAmount),
                  icon: Icons.summarize_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MetricCard(
                  label: 'عدد النتائج'.tr(context, 'Result count'),
                  value: '$_totalCount',
                  icon: Icons.numbers_rounded,
                  tint: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _error != null && _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 54,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!.tr(
                          context,
                          _error == 'تعذر تحميل البيانات'
                              ? 'Could not load data'
                              : 'Could not load more data',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: _loadInitial,
                        child: Text('إعادة المحاولة'.tr(context, 'Try again')),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.search_off_rounded,
                        size: 54,
                        color: Colors.black26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد معاملات تطابق الفلاتر'.tr(
                          context,
                          'No transactions match the filters',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    if (i == _items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: _error != null
                              ? TextButton(
                                  onPressed: _loadMore,
                                  child: Text(
                                    'إعادة المحاولة'.tr(context, 'Try again'),
                                  ),
                                )
                              : const CircularProgressIndicator(),
                        ),
                      );
                    }
                    return TransactionTile(
                      item: _items[i],
                      store: widget.store,
                      onEdit: _editExpense,
                      onDelete: _deleteExpense,
                    );
                  },
                ),
        ),
      ],
    ),
  );

  Future<void> _editExpense(Expense expense) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(store: widget.store, expense: expense),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف المصروف؟'.tr(context, 'Delete expense?')),
        content: Text(
          context.isArabic
              ? 'سيتم حذف ${money(context, expense.amount)} وتحديث الرصيد والملخص تلقائيًا.'
              : '${money(context, expense.amount)} will be deleted and totals updated automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'.tr(context, 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف'.tr(context, 'Delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.store.deleteExpense(expense.id);
    } on PersistenceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.localizedError(context))),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حذف المصروف وتحديث البيانات'.tr(
            context,
            'Expense deleted and data updated',
          ),
        ),
      ),
    );
  }
}
