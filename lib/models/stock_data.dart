import 'package:json_annotation/json_annotation.dart';

part 'stock_data.g.dart';

@JsonSerializable()
class StockData {
  final String ticker;
  final String price;

  const StockData({
    required this.ticker,
    required this.price,
  });

  factory StockData.fromJson(Map<String, dynamic> json) => _$StockDataFromJson(json);
  Map<String, dynamic> toJson() => _$StockDataToJson(this);

  double get priceAsDouble => double.tryParse(price) ?? 0.0;

  @override
  String toString() => 'StockData(ticker: $ticker, price: $price)';
} 