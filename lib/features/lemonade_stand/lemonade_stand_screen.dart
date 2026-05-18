import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aziz_academy/core/providers/coin_provider.dart';
import 'package:aziz_academy/core/router/app_router.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/theme/app_text_styles.dart';
import 'package:aziz_academy/core/utils/digits.dart';
import 'package:aziz_academy/core/l10n/context_ext.dart';

class LemonadeStandScreen extends ConsumerStatefulWidget {
  const LemonadeStandScreen({super.key});

  @override
  ConsumerState<LemonadeStandScreen> createState() =>
      _LemonadeStandScreenState();
}

enum _Weather { sunny, cloudy, rainy, hot }

class _LemonadeStandScreenState extends ConsumerState<LemonadeStandScreen> {
  static const _days = 7;
  static const double _costPerCup = 0.20;

  int _day = 1;
  double _bank = 5.00;
  double _price = 0.50;
  int _cups = 20;
  late _Weather _weather;
  String? _msg;
  bool _gameOver = false;
  bool _awarded = false;

  @override
  void initState() {
    super.initState();
    _weather = _rollWeather();
  }

  _Weather _rollWeather() {
    final rng = math.Random();
    final r = rng.nextDouble();
    if (r < 0.20) return _Weather.hot;
    if (r < 0.55) return _Weather.sunny;
    if (r < 0.85) return _Weather.cloudy;
    return _Weather.rainy;
  }

  /// Demand model: base demand depends on weather, then scales inversely
  /// with price. Sweet spot around $0.40-$0.60.
  int _calcDemand(_Weather w, double price) {
    final rng = math.Random();
    final base = switch (w) {
      _Weather.hot => 60,
      _Weather.sunny => 40,
      _Weather.cloudy => 22,
      _Weather.rainy => 8,
    };
    // Demand drops as price increases.
    final priceFactor = (1.0 - (price - 0.30) * 1.2).clamp(0.05, 1.4);
    final noise = 0.85 + rng.nextDouble() * 0.30;
    return (base * priceFactor * noise).round().clamp(0, 80);
  }

  void _runDay() {
    if (_gameOver) return;
    HapticFeedback.lightImpact();
    final demand = _calcDemand(_weather, _price);
    final sold = math.min(demand, _cups);
    final revenue = sold * _price;
    final cost = _cups * _costPerCup;
    final profit = revenue - cost;
    setState(() {
      _bank = (_bank + profit).clamp(-100, 999);
      _msg =
          '${_weatherEmoji(_weather)} Sold $sold/$_cups (demand $demand). Profit ${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}';
      _day += 1;
      if (_day > _days) {
        _gameOver = true;
        _award();
      } else {
        _weather = _rollWeather();
      }
    });
  }

  String _weatherEmoji(_Weather w) {
    switch (w) {
      case _Weather.sunny:
        return '☀️';
      case _Weather.cloudy:
        return '☁️';
      case _Weather.rainy:
        return '🌧️';
      case _Weather.hot:
        return '🥵';
    }
  }

  String _weatherLabel(_Weather w, bool isAr) {
    switch (w) {
      case _Weather.sunny:
        return isAr ? 'مشمس' : 'Sunny';
      case _Weather.cloudy:
        return isAr ? 'غائم' : 'Cloudy';
      case _Weather.rainy:
        return isAr ? 'ممطر' : 'Rainy';
      case _Weather.hot:
        return isAr ? 'حار جدًا' : 'Hot!';
    }
  }

  void _newGame() {
    setState(() {
      _day = 1;
      _bank = 5.00;
      _price = 0.50;
      _cups = 20;
      _weather = _rollWeather();
      _msg = null;
      _gameOver = false;
      _awarded = false;
    });
  }

  void _award() {
    if (_awarded) return;
    _awarded = true;
    HapticFeedback.heavyImpact();
    int reward;
    if (_bank >= 25) {
      reward = 10;
    } else if (_bank >= 15) {
      reward = 5;
    } else if (_bank >= 8) {
      reward = 2;
    } else {
      reward = 0;
    }
    if (reward > 0) {
      ref.read(coinProvider.notifier).award(reward);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: context.l10n.commonBack,
          icon: Icon(
            isAr ? Icons.arrow_forward : Icons.arrow_back,
            color: AppColors.textDark,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Text(
          isAr ? 'كشك الليمون' : 'Lemonade Stand',
          style: AppTextStyles.headingSmall,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _newGame),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isAr
                      ? 'حدد السعر وعدد الأكواب لكل يوم. كل كوب يكلف \$٠٫٢٠. الطقس يؤثر على الزبائن.'
                      : 'Set price and cups each day. Each cup costs \$0.20 to make. Weather affects demand.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Pill(
                      label: isAr ? 'اليوم' : 'Day',
                      value:
                          '${localizeDigits(math.min(_day, _days), arabic: isAr)}/${localizeDigits(_days, arabic: isAr)}',
                      color: AppColors.textDark,
                    ),
                    _Pill(
                      label: isAr ? 'الرصيد' : 'Bank',
                      value: '\$${_bank.toStringAsFixed(2)}',
                      color: _bank >= 5 ? AppColors.success : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'توقعات اليوم' : 'Today\'s forecast',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _weatherEmoji(_weather),
                        style: const TextStyle(fontSize: 64),
                      ),
                      Text(
                        _weatherLabel(_weather, isAr),
                        style: AppTextStyles.headingSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_msg != null && !_gameOver)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _msg!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (!_gameOver) ...[
                  Text(
                    isAr
                        ? 'السعر: \$${_price.toStringAsFixed(2)}'
                        : 'Price: \$${_price.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Slider(
                    value: _price,
                    min: 0.10,
                    max: 1.00,
                    divisions: 18,
                    label: '\$${_price.toStringAsFixed(2)}',
                    onChanged: (v) => setState(() => _price = v),
                  ),
                  Text(
                    isAr
                        ? 'الأكواب: ${localizeDigits(_cups, arabic: true)}'
                        : 'Cups to make: $_cups',
                    style: AppTextStyles.bodyMedium,
                  ),
                  Slider(
                    value: _cups.toDouble(),
                    min: 0,
                    max: 60,
                    divisions: 60,
                    label: '$_cups',
                    onChanged: (v) => setState(() => _cups = v.round()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'تكلفة اليوم: \$${(_cups * _costPerCup).toStringAsFixed(2)}'
                        : 'Today\'s cost: \$${(_cups * _costPerCup).toStringAsFixed(2)}',
                    style: AppTextStyles.labelSmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _runDay,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(isAr ? 'افتح الكشك!' : 'Open the stand!'),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isAr ? '🎉 انتهى الأسبوع!' : '🎉 Week complete!',
                          style: AppTextStyles.headingSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'الرصيد النهائي: \$${_bank.toStringAsFixed(2)}'
                              : 'Final bank: \$${_bank.toStringAsFixed(2)}',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _newGame,
                    icon: const Icon(Icons.replay),
                    label: Text(isAr ? 'مرة أخرى' : 'Play again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(width: 6),
          Text(value, style: AppTextStyles.headingSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
