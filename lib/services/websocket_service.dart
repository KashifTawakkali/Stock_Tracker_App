import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/stock_data.dart';

enum ConnectionStatus {
  connecting,
  connected,
  reconnecting,
  disconnected,
}

class WebSocketService {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator/desktop, or your Mac's IP for physical devices
  static const String _wsUrl = 'ws://192.168.23.149:8080/ws';
  // static const String _wsUrl = 'ws://localhost:8080/ws';
  // static const String _wsUrl = 'ws://10.0.2.2:8080/ws'; // For Android emulator
  static const int _maxReconnectDelay = 30; // seconds
  static const int _initialReconnectDelay = 2; // seconds
  
  WebSocketChannel? _channel;
  StreamController<List<StockData>>? _dataController;
  StreamController<ConnectionStatus>? _statusController;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _currentReconnectDelay = _initialReconnectDelay;
  bool _isConnecting = false;
  bool _isDisposed = false;
  StreamSubscription? _streamSubscription;
  
  // Anomaly detection thresholds
  static const double _minPriceThreshold = 1.0; // Minimum valid price
  
  Stream<List<StockData>> get dataStream => _dataController!.stream;
  Stream<ConnectionStatus> get statusStream => _statusController!.stream;
  
  WebSocketService() {
    _dataController = StreamController<List<StockData>>.broadcast();
    _statusController = StreamController<ConnectionStatus>.broadcast();
  }
  
  void connect() {
    if (_isConnecting || _isDisposed) return;
    _isConnecting = true;
    _updateStatus(ConnectionStatus.connecting);
    
    try {
      print('Attempting to connect to $_wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      
      _streamSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnection,
        onError: _handleError,
        cancelOnError: false,
      );
      
      _updateStatus(ConnectionStatus.connected);
      _isConnecting = false;
      _currentReconnectDelay = _initialReconnectDelay;
      
      // Start heartbeat to keep connection alive
      _startHeartbeat();
      
      print('WebSocket connected successfully!');
    } catch (e) {
      print('Connection error: $e');
      _isConnecting = false;
      _handleDisconnection();
    }
  }
  
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDisposed && _channel != null) {
        try {
          _channel!.sink.add('{"type": "ping", "timestamp": "${DateTime.now().toIso8601String()}"}');
          print('Sent heartbeat ping');
        } catch (e) {
          print('Error sending heartbeat: $e');
          _handleDisconnection();
        }
      }
    });
  }
  
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _streamSubscription?.cancel();
    _channel?.sink.close();
    _updateStatus(ConnectionStatus.disconnected);
    _isConnecting = false;
  }
  
  void _handleMessage(dynamic message) {
    try {
      final String messageStr = message.toString();
      print('Received message: $messageStr');
      
      // Handle heartbeat messages
      if (messageStr.contains('"type":"heartbeat"') || messageStr.contains('"type":"ping"')) {
        print('Received heartbeat/ping, sending pong');
        if (!_isDisposed && _channel != null) {
          _channel!.sink.add('{"type": "pong", "timestamp": "${DateTime.now().toIso8601String()}"}');
        }
        return;
      }
      
      // Try to parse as JSON
      final List<dynamic> jsonData = jsonDecode(messageStr);
      final List<StockData> stockDataList = jsonData
          .map((json) => StockData.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Basic validation - pass all data to StockState for advanced anomaly detection
      final List<StockData> validData = _validateBasicData(stockDataList);
      
      if (validData.isNotEmpty) {
        print('Sending ${validData.length} valid stock data items to UI');
        _dataController!.add(validData);
      }
    } catch (e) {
      print('Error parsing message: $e');
      // Silently discard malformed data
    }
  }
  
  List<StockData> _validateBasicData(List<StockData> data) {
    final List<StockData> validData = [];
    
    for (final stock in data) {
      if (_isValidBasicData(stock)) {
        validData.add(stock);
      } else {
        print('Basic validation failed for ${stock.ticker}: price ${stock.price}');
      }
    }
    
    return validData;
  }
  
  bool _isValidBasicData(StockData stock) {
    final price = stock.priceAsDouble;
    
    // Check minimum price threshold
    if (price < _minPriceThreshold) {
      return false;
    }
    
    return true;
  }
  
  void _handleDisconnection() {
    if (_isDisposed) return;
    
    print('WebSocket disconnected');
    _updateStatus(ConnectionStatus.disconnected);
    _isConnecting = false;
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _heartbeatTimer?.cancel();
    
    if (!_isDisposed) {
      _scheduleReconnect();
    }
  }
  
  void _handleError(dynamic error) {
    if (_isDisposed) return;
    
    print('WebSocket error: $error');
    _handleDisconnection();
  }
  
  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true || _isDisposed) return;
    
    _updateStatus(ConnectionStatus.reconnecting);
    
    _reconnectTimer = Timer(Duration(seconds: _currentReconnectDelay), () {
      if (!_isDisposed) {
        print('Attempting to reconnect...');
        connect();
        
        // Exponential backoff with cap
        _currentReconnectDelay = min(_currentReconnectDelay * 2, _maxReconnectDelay);
      }
    });
  }
  
  void _updateStatus(ConnectionStatus status) {
    if (!_isDisposed) {
      _statusController!.add(status);
    }
  }
  
  void dispose() {
    _isDisposed = true;
    disconnect();
    _dataController?.close();
    _statusController?.close();
  }
} 