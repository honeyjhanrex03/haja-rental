import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RealTimeClock extends StatefulWidget {
  final TextStyle? style;
  const RealTimeClock({super.key, this.style});

  @override
  State<RealTimeClock> createState() => _RealTimeClockState();
}

class _RealTimeClockState extends State<RealTimeClock> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('hh:mm:ss a').format(_currentTime),
      style: widget.style ?? const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    );
  }
}
