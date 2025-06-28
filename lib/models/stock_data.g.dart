// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockData _$StockDataFromJson(Map<String, dynamic> json) => StockData(
      ticker: json['ticker'] as String,
      price: json['price'] as String,
    );

Map<String, dynamic> _$StockDataToJson(StockData instance) => <String, dynamic>{
      'ticker': instance.ticker,
      'price': instance.price,
    };
