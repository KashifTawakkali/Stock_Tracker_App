import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'stock_data.dart';

class StockState extends ChangeNotifier {
  final Map<String, StockInfo> _stocks = {};
  final Map<String, List<double>> _priceHistory = {};
  
  // Performance optimizations
  Timer? _debounceTimer;
  bool _isLoading = true;
  final Set<String> _changedStocks = {};
  
  // Anomaly detection configuration
  static const int _maxHistorySize = 10;
  static const double _maxPriceChangePercent = 30.0; // 30% max change
  static const double _minPriceThreshold = 1.0;
  
  Map<String, StockInfo> get stocks => Map.unmodifiable(_stocks);
  bool get isLoading => _isLoading;
  
  void updateStocks(List<StockData> newData) {
    if (newData.isEmpty) return;
    
    print('StockState: Received ${newData.length} stock data items');
    bool hasChanges = false;
    
    for (final stockData in newData) {
      final ticker = stockData.ticker;
      final newPrice = stockData.priceAsDouble;
      
      // Initialize if not exists
      if (!_stocks.containsKey(ticker)) {
        _stocks[ticker] = StockInfo(
          ticker: ticker,
          price: newPrice,
          previousPrice: newPrice,
          isAnomalous: false,
          lastUpdate: DateTime.now(),
        );
        _priceHistory[ticker] = [newPrice];
        _changedStocks.add(ticker);
        hasChanges = true;
        print('StockState: Added new stock $ticker');
        continue;
      }
      
      final stockInfo = _stocks[ticker]!;
      final oldPrice = stockInfo.price;
      
      // Only update if price actually changed
      if ((newPrice - oldPrice).abs() > 0.001) {
        // Check for anomalies
        final isAnomalous = _detectAnomaly(ticker, newPrice);
        
        if (!isAnomalous) {
          // Update price history
          _updatePriceHistory(ticker, newPrice);
          
          // Update stock info
          _stocks[ticker] = StockInfo(
            ticker: ticker,
            price: newPrice,
            previousPrice: oldPrice,
            isAnomalous: false,
            lastUpdate: DateTime.now(),
          );
          _changedStocks.add(ticker);
          hasChanges = true;
          print('StockState: Updated $ticker from $oldPrice to $newPrice');
        } else {
          // Mark as anomalous but keep old price
          _stocks[ticker] = StockInfo(
            ticker: ticker,
            price: oldPrice,
            previousPrice: stockInfo.previousPrice,
            isAnomalous: true,
            lastUpdate: DateTime.now(),
          );
          _changedStocks.add(ticker);
          hasChanges = true;
          print('StockState: Marked $ticker as anomalous, keeping price $oldPrice');
        }
      }
    }
    
    // Set loading to false after first data
    if (_isLoading) {
      _isLoading = false;
      hasChanges = true;
    }
    
    // Debounce notifications for better performance
    if (hasChanges) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        print('StockState: Notifying listeners of changes for ${_changedStocks.length} stocks');
        _changedStocks.clear();
        notifyListeners();
      });
    }
  }
  
  bool _detectAnomaly(String ticker, double newPrice) {
    // Check minimum price threshold
    if (newPrice < _minPriceThreshold) {
      print('Anomaly detected for $ticker: price $newPrice below minimum threshold');
      return true;
    }
    
    final history = _priceHistory[ticker];
    if (history == null || history.isEmpty) {
      return false; // First price, can't detect anomaly
    }
    
    final lastPrice = history.last;
    final priceChange = ((newPrice - lastPrice) / lastPrice) * 100;
    
    // Check for extreme price changes
    if (priceChange.abs() > _maxPriceChangePercent) {
      print('Anomaly detected for $ticker: price change ${priceChange.toStringAsFixed(2)}% exceeds threshold');
      return true;
    }
    
    // Check for statistical anomalies (if we have enough history)
    if (history.length >= 3) {
      final mean = history.reduce((a, b) => a + b) / history.length;
      final variance = history.map((p) => (p - mean) * (p - mean)).reduce((a, b) => a + b) / history.length;
      final stdDev = sqrt(variance);
      
      // If new price is more than 2 standard deviations from mean
      if ((newPrice - mean).abs() > 2 * stdDev) {
        print('Anomaly detected for $ticker: price $newPrice is statistically anomalous');
        return true;
      }
    }
    
    return false;
  }
  
  void _updatePriceHistory(String ticker, double price) {
    final history = _priceHistory[ticker] ?? [];
    history.add(price);
    
    // Keep only recent history
    if (history.length > _maxHistorySize) {
      history.removeAt(0);
    }
    
    _priceHistory[ticker] = history;
  }
  
  StockInfo? getStock(String ticker) {
    return _stocks[ticker];
  }
  
  void clearAnomalyFlag(String ticker) {
    final stock = _stocks[ticker];
    if (stock != null && stock.isAnomalous) {
      _stocks[ticker] = StockInfo(
        ticker: stock.ticker,
        price: stock.price,
        previousPrice: stock.previousPrice,
        isAnomalous: false,
        lastUpdate: DateTime.now(),
      );
      notifyListeners();
    }
  }
}

class StockInfo {
  final String ticker;
  final double price;
  final double previousPrice;
  final bool isAnomalous;
  final DateTime lastUpdate;
  
  const StockInfo({
    required this.ticker,
    required this.price,
    required this.previousPrice,
    required this.isAnomalous,
    required this.lastUpdate,
  });
  
  double get priceChange => price - previousPrice;
  double get priceChangePercent => previousPrice != 0 ? (priceChange / previousPrice) * 100 : 0;
  bool get isPriceUp => priceChange > 0;
  bool get isPriceDown => priceChange < 0;
  
  @override
  String toString() => 'StockInfo(ticker: $ticker, price: $price, isAnomalous: $isAnomalous)';
} 