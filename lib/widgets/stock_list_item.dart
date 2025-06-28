import 'package:flutter/material.dart';
import '../models/stock_state.dart';

class StockListItem extends StatefulWidget {
  final StockInfo stock;

  const StockListItem({
    super.key,
    required this.stock,
  });

  @override
  State<StockListItem> createState() => _StockListItemState();
}

class _StockListItemState extends State<StockListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  Color? _previousColor;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(StockListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger animation if price changed significantly
    if ((oldWidget.stock.price - widget.stock.price).abs() > 0.01 && 
        !widget.stock.isAnomalous) {
      _triggerPriceChangeAnimation();
    }
  }

  void _triggerPriceChangeAnimation() {
    final newColor = widget.stock.isPriceUp ? Colors.green : Colors.red;
    
    if (_previousColor != newColor) {
      _colorAnimation = ColorTween(
        begin: _previousColor ?? Colors.transparent,
        end: newColor,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse();
        }
      });
      
      _previousColor = newColor;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value * 0.02 + 0.98,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _colorAnimation.value?.withOpacity(0.15) ?? Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: widget.stock.isAnomalous 
                    ? Colors.orange 
                    : Colors.grey.shade300.withOpacity(0.5),
                width: widget.stock.isAnomalous ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              backgroundBlendMode: BlendMode.overlay,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              leading: _buildLeadingIcon(),
              title: Row(
                children: [
                  Text(
                    widget.stock.ticker,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.stock.isAnomalous 
                          ? Colors.orange.shade800 
                          : Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (widget.stock.isAnomalous) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                'Last updated: ${_formatTime(widget.stock.lastUpdate)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade300,
                  fontStyle: FontStyle.italic,
                ),
              ),
              trailing: _buildTrailingPrice(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeadingIcon() {
    if (widget.stock.isAnomalous) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.warning,
          color: Colors.orange.shade800,
          size: 20,
        ),
      );
    }

    IconData iconData;
    Color iconColor;

    if (widget.stock.isPriceUp) {
      iconData = Icons.trending_up;
      iconColor = Colors.green;
    } else if (widget.stock.isPriceDown) {
      iconData = Icons.trending_down;
      iconColor = Colors.red;
    } else {
      iconData = Icons.remove;
      iconColor = Colors.grey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildTrailingPrice() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${widget.stock.price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.stock.isAnomalous 
                ? Colors.orange.shade800 
                : Colors.white,
            letterSpacing: 1.1,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        if (!widget.stock.isAnomalous) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.stock.isPriceUp 
                    ? Icons.keyboard_arrow_up 
                    : Icons.keyboard_arrow_down,
                color: widget.stock.isPriceUp ? Colors.greenAccent : Colors.redAccent,
                size: 18,
              ),
              Text(
                '${widget.stock.priceChangePercent.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 13,
                  color: widget.stock.isPriceUp ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.05,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
} 