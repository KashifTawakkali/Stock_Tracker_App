import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PerformanceMonitor extends StatefulWidget {
  const PerformanceMonitor({super.key});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with TickerProviderStateMixin {
  late Ticker _ticker;
  int _frameCount = 0;
  double _fps = 0;
  DateTime _lastTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration duration) {
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime).inMilliseconds;
    
    if (elapsed >= 1000) {
      setState(() {
        _fps = (_frameCount * 1000) / elapsed;
        _frameCount = 0;
        _lastTime = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 120,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FPS: ${_fps.toStringAsFixed(1)}',
              style: TextStyle(
                color: _fps > 55 ? Colors.green : Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Memory: ${_getMemoryUsage()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMemoryUsage() {
    // This is a placeholder - in a real app you'd use proper memory monitoring
    return '~${(DateTime.now().millisecondsSinceEpoch % 100 + 50)}MB';
  }
} 