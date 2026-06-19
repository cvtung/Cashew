import 'dart:async';
import 'package:budget/struct/currencyFunctions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/util/onAppResume.dart';
import 'package:flutter/material.dart';

/// Periodically fetches the gold (luongvang) exchange rate and writes it into
/// [cachedCurrencyExchange] so conversions stay accurate without waiting for a
/// full manual sync.
class WatchForExchangeRateUpdate extends StatefulWidget {
  final Widget child;
  const WatchForExchangeRateUpdate({required this.child, super.key});

  @override
  State<WatchForExchangeRateUpdate> createState() =>
      _WatchForExchangeRateUpdateState();
}

class _WatchForExchangeRateUpdateState
    extends State<WatchForExchangeRateUpdate> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Also fetch immediately on first mount so gold rate is ready before the
    // user interacts with any gold-denominated account.
    _refreshGoldRate();
  }

  void _startTimer() {
    _timer?.cancel();
    // Refresh gold rate every 30 minutes while the app is in foreground.
    _timer = Timer.periodic(const Duration(minutes: 30), (_) {
      if (appLifecycleState == AppLifecycleState.resumed) {
        _refreshGoldRate();
      }
    });
  }

  Future<void> _refreshGoldRate() async {
    Map<String, dynamic> result = await fetchGoldRate();
    if (result["ok"] == true) {
      Map<dynamic, dynamic> cached =
          Map.from(appStateSettings["cachedCurrencyExchange"] ?? {});
      cached["luongvang"] = result["stored"];
      updateSettings("cachedCurrencyExchange", cached,
          updateGlobalState: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
