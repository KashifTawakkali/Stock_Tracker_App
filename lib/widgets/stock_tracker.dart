import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stock_state.dart';
import '../services/websocket_service.dart';
import 'connection_status_bar.dart';
import 'optimized_stock_list.dart';

class StockTracker extends StatefulWidget {
  const StockTracker({super.key});

  @override
  State<StockTracker> createState() => _StockTrackerState();
}

class _StockTrackerState extends State<StockTracker> {
  static WebSocketService? _webSocketService;
  static StockState? _stockState;
  StreamSubscription? _dataSubscription;

  @override
  void initState() {
    super.initState();
    
    // Create singleton instances
    _webSocketService ??= WebSocketService();
    _stockState ??= StockState();
    
    // Connect to WebSocket if not already connected
    _webSocketService!.connect();
    
    // Listen to data updates
    _dataSubscription = _webSocketService!.dataStream.listen((data) {
      _stockState!.updateStocks(data);
    });
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    // Don't dispose the singleton services here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _stockState!),
        StreamProvider<ConnectionStatus>.value(
          value: _webSocketService!.statusStream,
          initialData: ConnectionStatus.disconnected,
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Stock Price Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.2)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF232526), Color(0xFF414345)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 100),
              const ConnectionStatusBar(),
              const SizedBox(height: 8),
              Expanded(
                child: Consumer<StockState>(
                  builder: (context, stockState, child) {
                    final stocks = stockState.stocks.values.toList();
                    return OptimizedStockList(
                      stocks: stocks,
                      isLoading: stockState.isLoading,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 