import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// أقل وأكبر مدة تجهيز السيرفر بيقبلها بالدقايق (30 يوم)
const int minPreparationMinutes = 1;
const int maxPreparationMinutes = 43200;

/// "4 ساعات" أو "يومان" أو "يوم و 3 ساعات" من عدد الدقايق
String formatPreparationDuration(int minutes) {
  final days = minutes ~/ 1440;
  final hours = (minutes % 1440) ~/ 60;
  final mins = minutes % 60;
  final parts = [
    if (days > 0) 'days_count'.plural(days),
    if (hours > 0) 'hours_count'.plural(hours),
    if (mins > 0) 'minutes_count'.plural(mins),
  ];
  if (parts.isEmpty) return 'minutes_count'.plural(0);
  return parts.join(' ${'and_separator'.tr()} ');
}

/// العدّاد: "02:15:40"، ولو فاضل أكتر من يوم "يومان 03:20"
String formatCountdown(Duration duration) {
  final value = duration.isNegative ? -duration : duration;
  String two(int n) => n.toString().padLeft(2, '0');
  final days = value.inDays;
  final hours = two(value.inHours % 24);
  final minutes = two(value.inMinutes % 60);
  if (days > 0) return '${'days_count'.plural(days)} $hours:$minutes';
  return '$hours:$minutes:${two(value.inSeconds % 60)}';
}

/// "اليوم 4:30 م" أو "غداً 10:00 ص" أو "15 نوفمبر 9:00 ص" بالتوقيت المحلي
String formatReadyAt(DateTime utc, String locale) {
  final local = utc.toLocal();
  final now = DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final diff = day.difference(DateTime(now.year, now.month, now.day)).inDays;
  final dayText = switch (diff) {
    0 => 'today'.tr(),
    1 => 'tomorrow'.tr(),
    _ => DateFormat('d MMMM', locale).format(local),
  };
  final time = DateFormat('h:mm', locale).format(local);
  final period = local.hour < 12 ? 'am_short'.tr() : 'pm_short'.tr();
  return '$dayText $time $period';
}

/// بيبني الـ child كل ثانية بالوقت الفاضل لحد [target]،
/// وبيبقى بالسالب لما الموعد يعدّي
class CountdownBuilder extends StatefulWidget {
  final DateTime target;
  final Widget Function(BuildContext context, Duration remaining) builder;

  const CountdownBuilder({
    super.key,
    required this.target,
    required this.builder,
  });

  @override
  State<CountdownBuilder> createState() => _CountdownBuilderState();
}

class _CountdownBuilderState extends State<CountdownBuilder> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.target.difference(DateTime.now().toUtc()));
}
