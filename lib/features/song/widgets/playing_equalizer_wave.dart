import 'package:flutter/material.dart';

class PlayingEqualizerWave extends StatefulWidget {
  final Color color;
  final double width;
  final double height;
  final bool isAnimated;

  const PlayingEqualizerWave({
    super.key,
    required this.color,
    this.width = 16,
    this.height = 16,
    this.isAnimated = true,
  });

  @override
  State<PlayingEqualizerWave> createState() => _PlayingEqualizerWaveState();
}

class _PlayingEqualizerWaveState extends State<PlayingEqualizerWave> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final int _barCount = 3;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_barCount, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 350 + (index * 120)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.isAnimated) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant PlayingEqualizerWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _startAnimation();
      } else {
        _stopAnimation();
      }
    }
  }

  void _startAnimation() {
    for (final controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  void _stopAnimation() {
    for (final controller in _controllers) {
      controller.stop();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: widget.width / (_barCount * 1.5),
                height: widget.height * _animations[index].value,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
