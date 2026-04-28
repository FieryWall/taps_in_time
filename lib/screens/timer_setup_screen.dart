import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tap_screen.dart';

class TimerSetupScreen extends StatefulWidget {
  const TimerSetupScreen({super.key});

  @override
  State<TimerSetupScreen> createState() => _TimerSetupScreenState();
}

class _TimerSetupScreenState extends State<TimerSetupScreen> {
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _minutesFocus = FocusNode();
  final _secondsFocus = FocusNode();

  bool get _isValid {
    final minutes = int.tryParse(_minutesController.text) ?? -1;
    final seconds = int.tryParse(_secondsController.text) ?? -1;
    if (minutes < 0 || seconds < 0) return false;
    if (seconds > 59) return false;
    final total = minutes * 60 + seconds;
    return total > 0 && total <= 5999;
  }

  int get _totalSeconds {
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    return minutes * 60 + seconds;
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocus.dispose();
    _secondsFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Set Timer',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeField(
                    controller: _minutesController,
                    focusNode: _minutesFocus,
                    label: 'MM',
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _secondsFocus.requestFocus(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  _buildTimeField(
                    controller: _secondsController,
                    focusNode: _secondsFocus,
                    label: 'SS',
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (_isValid) _startGame();
                    },
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: _isValid
                    ? Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: SizedBox(
                          width: double.infinity,
                          height: 72,
                          child: FilledButton(
                            onPressed: _startGame,
                            style: FilledButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Start'),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
  }) {
    return SizedBox(
      width: 100,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          counterText: '',
          hintText: label,
          hintStyle: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          border: const UnderlineInputBorder(),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      ),
    );
  }

  void _startGame() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TapScreen(totalSeconds: _totalSeconds),
      ),
    );
  }
}
