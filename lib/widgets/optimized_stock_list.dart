import 'package:flutter/material.dart';
import '../models/stock_state.dart';
import 'stock_list_item.dart';
import 'shimmer_loading.dart';

class OptimizedStockList extends StatefulWidget {
  final List<StockInfo> stocks;
  final bool isLoading;

  const OptimizedStockList({
    super.key,
    required this.stocks,
    required this.isLoading,
  });

  @override
  State<OptimizedStockList> createState() => _OptimizedStockListState();
}

class _OptimizedStockListState extends State<OptimizedStockList> {
  static const int _pageSize = 20;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (!_isLoadingMore && _currentPage * _pageSize < widget.stocks.length) {
      setState(() {
        _isLoadingMore = true;
      });

      // Simulate loading delay for smooth UX
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _currentPage++;
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  List<StockInfo> get _visibleStocks {
    final endIndex = (_currentPage + 1) * _pageSize;
    return widget.stocks.take(endIndex).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const ShimmerLoading();
    }

    if (widget.stocks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Waiting for stock data...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: _visibleStocks.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _visibleStocks.length) {
          // Loading indicator at the bottom
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          );
        }

        final stock = _visibleStocks[index];
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 200 + (index % 8) * 30),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: StockListItem(stock: stock),
                ),
              ),
            );
          },
        );
      },
    );
  }
} 