import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/app_time.dart';

mixin DateRefreshMixin<T extends StatefulWidget> on State<T> {
  Timer? _dateRefreshTimer;
  DateTime? _lastKnownDate;

  void onDateChanged() {}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this as WidgetsBindingObserver);

    _lastKnownDate = _dateOnly(AppTime.now());
    _scheduleNextDateRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    _dateRefreshTimer?.cancel();
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  void _handleResume() {
    final nowDate = _dateOnly(AppTime.now());

    if (_lastKnownDate == null || !_isSameDate(_lastKnownDate!, nowDate)) {
      _lastKnownDate = nowDate;
      onDateChanged();
    }

    _scheduleNextDateRefresh();
  }

  void _scheduleNextDateRefresh() {
    _dateRefreshTimer?.cancel();

    final now = AppTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final duration = nextDay.difference(now);

    _dateRefreshTimer = Timer(duration, () {
      if (!mounted) return;

      _lastKnownDate = _dateOnly(AppTime.now());
      onDateChanged();
      _scheduleNextDateRefresh();
    });
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}