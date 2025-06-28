// File: mock_server.dart

import 'dart:io';

import 'dart:convert';

import 'dart:async';

import 'dart:math';

final Map<String, double> _stocks = {
  'AAPL': 150.00,
  'GOOG': 2800.00,
  'TSLA': 700.00,
  'MSFT': 300.00,
  'AMZN': 3400.00,
  'META': 350.00,
  'NVDA': 450.00,
  'NFLX': 500.00,
  'ADBE': 550.00,
  'CRM': 200.00,
  'PYPL': 180.00,
  'INTC': 45.00,
  'AMD': 120.00,
  'ORCL': 120.00,
  'IBM': 140.00,
  'CSCO': 50.00,
  'QCOM': 130.00,
  'TXN': 160.00,
  'AVGO': 550.00,
  'MU': 80.00,
  'ADI': 180.00,
  'KLAC': 350.00,
  'LRCX': 650.00,
  'ASML': 750.00,
  'TSM': 100.00,
  'SNOW': 180.00,
  'PLTR': 20.00,
  'COIN': 120.00,
  'SQ': 60.00,
  'UBER': 40.00,
  'LYFT': 15.00,
  'DASH': 80.00,
  'ZM': 70.00,
  'SPOT': 200.00,
  'SNAP': 12.00,
  'PINS': 25.00,
  'TWTR': 45.00,
  'RBLX': 35.00,
  'MTCH': 80.00,
  'OKTA': 90.00,
  'CRWD': 200.00,
  'ZS': 150.00,
  'NET': 80.00,
  'DDOG': 100.00,
  'MDB': 300.00,
  'ESTC': 80.00,
  'PATH': 20.00,
  'RNG': 60.00,
  'TEAM': 180.00,
  'WDAY': 200.00,
  'VEEV': 200.00,
  'ZM': 70.00,
};

final Random _random = Random();

final List<WebSocket> _sockets = [];

void main() async {

final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

print('Server listening on ws://${server.address.host}:${server.port}');

server.listen((HttpRequest req) {

if (req.uri.path == '/ws') {

WebSocketTransformer.upgrade(req).then((WebSocket socket) {

_handleSocket(socket);

});

}

});

Timer.periodic(const Duration(seconds: 1), (timer) {

_updateAndBroadcast();

});

// Send heartbeat every 10 seconds to keep connections alive
Timer.periodic(const Duration(seconds: 10), (timer) {
  _sendHeartbeat();
});
}

void _handleSocket(WebSocket socket) {

print('Client connected! Total clients: ${_sockets.length + 1}');

_sockets.add(socket);

if (_random.nextDouble() < 0.5) {

final disconnectTime = Duration(seconds: 10 + _random.nextInt(20));

Timer(disconnectTime, () {

if (_sockets.contains(socket)) {

print('Simulating a network drop for a client.');

socket.close();

}

});

}

socket.listen(

(data) {
  print('Received data from client: $data');
},

onDone: () {

print('Client disconnected! Total clients: ${_sockets.length - 1}');

_sockets.remove(socket);

},

onError: (error) {

print('Client error: $error');

_sockets.remove(socket);

},

);

}

void _sendHeartbeat() {
  if (_sockets.isNotEmpty) {
    print('Sending heartbeat to ${_sockets.length} clients');
    for (final socket in _sockets) {
      try {
        socket.add('{"type": "heartbeat", "timestamp": "${DateTime.now().toIso8601String()}"}');
      } catch (e) {
        print('Error sending heartbeat: $e');
        _sockets.remove(socket);
      }
    }
  }
}

void _updateAndBroadcast() {

_stocks.forEach((ticker, price) {

final change = (_random.nextDouble() * 2 - 1) * (price * 0.01);

_stocks[ticker] = max(0, price + change);

});

final data = _stocks.entries

.map((e) => {'ticker': e.key, 'price': e.value.toStringAsFixed(2)})

.toList();

// // Failure Case 1: Malformed JSON
// if (_random.nextDouble() < 0.1) {
// print('>>> Sending malformed data...');
// for (final socket in _sockets) {
// try {
//   socket.add('{"ticker": "MSFT", "price": }');
// } catch (e) {
//   print('Error sending malformed data: $e');
//   _sockets.remove(socket);
// }
// }
// return;
// }

// // Failure Case 2: Logically Anomalous Data (NEW)
// if (_random.nextDouble() < 0.08) {
// print('>>> Sending anomalous price for GOOG...');
// final anomalousData = List<Map<String, String>>.from(data);
// final googIndex = anomalousData.indexWhere((d) => d['ticker'] == 'GOOG');
// if (googIndex != -1) {
// // Price drops by over 95%, which is syntactically valid but logically suspect
// anomalousData[googIndex]['price'] = (_stocks['GOOG']! / 20).toStringAsFixed(2);
// }
// for (final socket in _sockets) {
// try {
//   socket.add(jsonEncode(anomalousData));
// } catch (e) {
//   print('Error sending anomalous data: $e');
//   _sockets.remove(socket);
// }
// }
// return;
// }

// Good Data Broadcast
if (_sockets.isNotEmpty) {

print('Broadcasting price updates to ${_sockets.length} clients...');

final jsonData = jsonEncode(data);

for (final socket in _sockets) {

try {
  socket.add(jsonData);
} catch (e) {
  print('Error broadcasting data: $e');
  _sockets.remove(socket);
}
}

}

} 