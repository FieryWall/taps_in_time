import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/history_entry.dart';
import '../services/history_store.dart';

class TapScreen extends StatefulWidget {
  final int totalSeconds;

  const TapScreen({super.key, required this.totalSeconds});

  @override
  State<TapScreen> createState() => _TapScreenState();
}

class _TapScreenState extends State<TapScreen> with TickerProviderStateMixin {
  int _tapCount = 0;
  late int _remainingMillis;
  late int _totalMillis;
  Timer? _timer;
  bool _finished = false;
  List<HistoryEntry> _history = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();
    _totalMillis = widget.totalSeconds * 1000;
    _remainingMillis = _totalMillis;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 0.3).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    _flashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _flashController.reverse();
      }
    });

    _startTimer();
  }

  void _startTimer() {
    const tick = Duration(milliseconds: 50);
    _timer = Timer.periodic(tick, (timer) {
      setState(() {
        _remainingMillis -= 50;
        if (_remainingMillis <= 0) {
          _remainingMillis = 0;
          _finished = true;
          timer.cancel();
          _pulseController.stop();
          HapticFeedback.heavyImpact();
          _saveResult();
        } else if (_remainingMillis <= 10000 &&
            !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      });
    });
  }

  Future<void> _saveResult() async {
    final entry = HistoryEntry(
      taps: _tapCount,
      durationSeconds: widget.totalSeconds,
      timestamp: DateTime.now(),
    );
    await HistoryStore.add(entry);
    final history = await HistoryStore.load();
    if (mounted) {
      setState(() => _history = history);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  String get _timerText {
    final totalSecs = (_remainingMillis / 1000).ceil();
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    if (_totalMillis == 0) return 0;
    return _remainingMillis / _totalMillis;
  }

  bool get _isUrgent => _remainingMillis <= 10000 && _remainingMillis > 0;

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return _buildResultScreen();
    }
    return _buildTapScreen();
  }

  Widget _buildTapScreen() {
    final urgentColor = Colors.red.shade400;
    final normalColor = Theme.of(context).colorScheme.primary;
    final timerColor = _isUrgent ? urgentColor : Colors.white;
    final progressColor = _isUrgent ? urgentColor : normalColor;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          _timer?.cancel();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isUrgent ? _pulseAnimation.value : 1.0,
                            child: Text(
                              _timerText,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: timerColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 64),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Listener(
                  onPointerUp: (_) {
                    if (!_finished) {
                      setState(() => _tapCount++);
                      _flashController.forward(from: 0.0);
                      HapticFeedback.lightImpact();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _flashAnimation,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            Theme.of(context).colorScheme.primaryContainer,
                            Colors.white,
                            _flashAnimation.value,
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_tapCount',
                          style: TextStyle(
                            fontSize: 96,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Time\'s up!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                '$_tapCount',
                style: const TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _tapCount == 1 ? 'tap' : 'taps',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 48),
              if (_history.length > 1) ...[
                SizedBox(
                  height: 160,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final entry = _history[index];
                        final em = entry.durationSeconds ~/ 60;
                        final es = entry.durationSeconds % 60;
                        final dur =
                            '${em.toString().padLeft(2, '0')}:${es.toString().padLeft(2, '0')}';
                        final isLatest = index == 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  dur,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(
                                        alpha: isLatest ? 0.8 : 0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  '${entry.taps}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isLatest
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: Colors.white.withValues(
                                        alpha: isLatest ? 1.0 : 0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  'taps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(
                                        alpha: isLatest ? 0.8 : 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: 200,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Restart',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
