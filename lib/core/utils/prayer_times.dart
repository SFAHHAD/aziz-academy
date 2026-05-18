import 'dart:math' as math;

/// Pure-Dart astronomical solar calculations for daily prayer times.
/// No network, no platform plugins. Uses the standard algorithms from
/// Khalid Shaukat / "Praytimes" public domain code paths.
///
/// Caveats: tabular calculation, ±2 minutes typical. Not a substitute for
/// a moon-sighting authority. Children should rely on their local masjid
/// for fasting/prayer authority — this widget is for awareness only.
class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  /// All times are returned in fractional hours (0..24) of the local date.
  final double fajr;
  final double sunrise;
  final double dhuhr;
  final double asr;
  final double maghrib;
  final double isha;

  static String formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Compute prayer times for a date at (lat, lon, tz). [tz] is hours from
  /// UTC (e.g. 3 for Riyadh). [method] selects the convention; default
  /// matches Umm al-Qura (used in Saudi Arabia).
  static PrayerTimes compute({
    required DateTime date,
    required double latitude,
    required double longitude,
    required double timezoneHours,
    PrayerMethod method = PrayerMethod.ummAlQura,
  }) {
    final params = method.params;
    final jd = _julianDay(date) - longitude / (15 * 24);
    final sun = _sunPosition(jd);
    final eqt = sun.equationOfTime;
    final decl = sun.declination;

    final dhuhr = 12 - eqt; // local solar noon (hours)
    final fajr = dhuhr - _hourAngle(params.fajrAngle, latitude, decl);
    final sunrise = dhuhr - _hourAngle(0.833, latitude, decl);
    final maghrib = dhuhr + _hourAngle(0.833, latitude, decl);
    final isha = dhuhr + _hourAngle(params.ishaAngle, latitude, decl);

    final asrFactor = params.asrShafii ? 1.0 : 2.0;
    final asrAngle = -_atan(
      1.0 / (asrFactor + math.tan(_rad((latitude - decl).abs()))),
    );
    final asr = dhuhr + _hourAngle(asrAngle, latitude, decl);

    return PrayerTimes(
      fajr: _toLocal(fajr, longitude, timezoneHours),
      sunrise: _toLocal(sunrise, longitude, timezoneHours),
      dhuhr: _toLocal(dhuhr, longitude, timezoneHours),
      asr: _toLocal(asr, longitude, timezoneHours),
      maghrib: _toLocal(maghrib, longitude, timezoneHours),
      isha: _toLocal(isha, longitude, timezoneHours),
    );
  }

  static double _toLocal(double hours, double lon, double tz) {
    final t = hours + tz - lon / 15;
    return (t % 24 + 24) % 24;
  }

  static double _julianDay(DateTime d) {
    int y = d.year;
    int m = d.month;
    final day = d.day + d.hour / 24 + d.minute / 1440;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = y ~/ 100;
    final b = 2 - a + (a ~/ 4);
    return ((365.25 * (y + 4716)).floor() +
            (30.6001 * (m + 1)).floor() +
            day +
            b -
            1524.5)
        .toDouble();
  }

  static _SunPos _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _norm(357.529 + 0.98560028 * d);
    final q = _norm(280.459 + 0.98564736 * d);
    final l = _norm(
      q + 1.915 * math.sin(_rad(g)) + 0.020 * math.sin(_rad(2 * g)),
    );
    final e = 23.439 - 0.00000036 * d;
    final ra =
        _atan2(math.cos(_rad(e)) * math.sin(_rad(l)), math.cos(_rad(l))) / 15;
    final eqt = q / 15 - _norm(ra * 1.0);
    final decl = _asin(math.sin(_rad(e)) * math.sin(_rad(l)));
    return _SunPos(
      equationOfTime: eqt > 12 ? eqt - 24 : eqt,
      declination: decl,
    );
  }

  static double _hourAngle(double angle, double lat, double decl) {
    final cosH =
        (-math.sin(_rad(angle)) - math.sin(_rad(lat)) * math.sin(_rad(decl))) /
        (math.cos(_rad(lat)) * math.cos(_rad(decl)));
    return _acos(cosH) / 15;
  }

  static double _norm(double v) => v - 360 * (v / 360).floor();
  static double _rad(double d) => d * math.pi / 180;
  static double _deg(double r) => r * 180 / math.pi;
  static double _atan2(double y, double x) => _deg(math.atan2(y, x));
  static double _atan(double v) => _deg(math.atan(v));
  static double _asin(double v) => _deg(math.asin(v));
  static double _acos(double v) => _deg(math.acos(v));
}

class _SunPos {
  _SunPos({required this.equationOfTime, required this.declination});
  final double equationOfTime;
  final double declination;
}

class PrayerMethodParams {
  const PrayerMethodParams({
    required this.fajrAngle,
    required this.ishaAngle,
    this.asrShafii = true,
  });
  final double fajrAngle;
  final double ishaAngle;
  final bool asrShafii;
}

enum PrayerMethod {
  ummAlQura(
    PrayerMethodParams(fajrAngle: 18.5, ishaAngle: 90.0 / 60),
  ), // Saudi Arabia
  egypt(PrayerMethodParams(fajrAngle: 19.5, ishaAngle: 17.5)),
  isna(PrayerMethodParams(fajrAngle: 15, ishaAngle: 15)),
  mwl(PrayerMethodParams(fajrAngle: 18, ishaAngle: 17)),
  karachi(PrayerMethodParams(fajrAngle: 18, ishaAngle: 18));

  const PrayerMethod(this.params);
  final PrayerMethodParams params;
}
