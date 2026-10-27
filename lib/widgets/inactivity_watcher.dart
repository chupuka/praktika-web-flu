import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warning;
  final VoidCallback onTimeout;
  final Widget child;
  final bool enabled;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warning,
    required this.onTimeout,
    required this.child,
    this.enabled = true,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _warningTimer;
  Timer? _endTimer;
  Timer? _ticker;
  bool _warning = false;
  bool _ending = false;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _restart();
  }

  @override
  void didUpdateWidget(InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        _restart();
      } else {
        _stop();
        if (_warning) setState(() => _warning = false);
      }
    }
  }

  bool _onKey(KeyEvent event) {
    _restart();
    return false;
  }

  Duration get _warningDelay {
    final delay = widget.timeout - widget.warning;
    return delay.isNegative ? Duration.zero : delay;
  }

  void _restart() {
    if (!widget.enabled || !mounted) return;
    _warningTimer?.cancel();
    _endTimer?.cancel();
    _ticker?.cancel();
    _ending = false;
    _secondsLeft = widget.warning.inSeconds;
    if (_warning) {
      setState(() => _warning = false);
    }
    _warningTimer = Timer(_warningDelay, _showWarning);
    _endTimer = Timer(widget.timeout, _timeout);
  }

  void _showWarning() {
    if (!mounted || !widget.enabled) return;
    setState(() {
      _warning = true;
      _secondsLeft = widget.warning.inSeconds;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft -= 1);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  void _timeout() {
    if (_ending) return;
    _ending = true;
    _stop();
    if (mounted) setState(() => _warning = false);
    widget.onTimeout();
  }

  void _stop() {
    _warningTimer?.cancel();
    _endTimer?.cancel();
    _ticker?.cancel();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restart(),
      onPointerMove: (_) => _restart(),
      onPointerSignal: (_) => _restart(),
      child: Stack(
        children: [
          widget.child,
          if (_warning)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Material(
                      elevation: 8,
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Сессия завершится через $_secondsLeft с',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            FilledButton(
                              onPressed: _restart,
                              child: const Text('Продолжить'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
