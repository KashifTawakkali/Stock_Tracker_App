import 'package:flutter/material.dart';
import 'widgets/stock_tracker.dart';
import 'config/app_config.dart';

void main() {
  // Print configuration for debugging
  AppConfig.printConfig();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Price Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StockTracker(),
    );
  }
}
