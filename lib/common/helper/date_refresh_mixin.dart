import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/app_time.dart';

mixin DateRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _dateRefreshTimer;

  @override
  void initState() {
    super.initState();
    _scheduleNextDateRefresh();
  }

  @override
  void dispose() {
    _dateRefreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextDateRefresh() {
    _dateRefreshTimer?.cancel();

    final now = AppTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final duration = nextDay.difference(now);

    _dateRefreshTimer = Timer(duration, () {
      if (!mounted) return;

      setState(() {});
      _scheduleNextDateRefresh();
    });
  }
}