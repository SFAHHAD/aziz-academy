import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aziz_academy/l10n/app_localizations.dart';
import 'package:aziz_academy/core/providers/app_settings_provider.dart';
import 'package:aziz_academy/core/providers/locale_provider.dart';
import 'package:aziz_academy/core/services/connectivity_watcher.dart';
import 'package:aziz_academy/core/services/supabase_bootstrap.dart';
import 'package:aziz_academy/core/theme/app_colors.dart';
import 'package:aziz_academy/core/widgets/break_reminder.dart';
import 'package:aziz_academy/core/widgets/error_boundary.dart';
import 'package:aziz_academy/features/admin/admin_error_log.dart';
import 'package:aziz_academy/features/admin/admin_traffic.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Replace Flutter's default red/gray error widget with a bilingual
  // friendly card + reload button. Triggered when any widget's build()
  // throws — the rest of the app keeps running underneath.
  ErrorWidget.builder = friendlyErrorWidgetBuilder;
  // Catch every framework error into the admin console's in-memory ring
  // buffer so the operator can review them at /x9k2-admin-portal → Errors.
  AdminErrorLog.install();
  // Record this app open for the on-device traffic counters. Fire-and-forget
  // so a SharedPreferences hiccup never blocks the UI.
  AdminTraffic.recordAppOpen();
  // Bring up the Supabase backend (parent accounts + cloud sync). Never
  // throws — the app stays fully playable as a guest if this fails.
  await initSupabase();
  // Lock phone to portrait; tablets and web stay free to rotate.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }
  runApp(const ProviderScope(child: AzizAcademyApp()));
}

class AzizAcademyApp extends ConsumerWidget {
  const AzizAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider).value;
    final reducedMotion = settings?.reducedMotion ?? false;
    final largerText = settings?.largerText ?? false;
    final dyslexiaFont = settings?.dyslexiaFont ?? false;
    final lightMode = settings?.lightMode ?? false;
    final localeAsync = ref.watch(localeProvider);

    final fontFamily = dyslexiaFont ? 'OpenDyslexic' : 'Cairo';

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,

      locale: localeAsync.value ?? const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      theme: AppTheme.buildTheme(fontFamily: fontFamily),
      darkTheme: AppTheme.buildTheme(fontFamily: fontFamily),
      themeMode: lightMode ? ThemeMode.light : ThemeMode.dark,

      routerConfig: appRouter,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        // Phones get full system scale; tablets get a small bump because
        // their bigger screens make default text feel small to kids; web
        // gets a slight reduction at very wide viewports.
        final widthTweak = screenWidth >= 1200
            ? 0.95
            : (screenWidth >= 720 ? 1.05 : 1.0);
        final system = mediaQuery.textScaler.scale(1.0);
        final largerBump = largerText ? 1.18 : 1.0;
        final combined = (system * widthTweak * largerBump).clamp(0.85, 1.6);

        // The admin console is an ops surface, not the kid-facing app.
        // Strip the kid-styled break reminder + connectivity banner when the
        // operator is inside /x9k2-admin-portal so the console looks like an
        // ops tool, not the same app in a different mode.
        final routeInfo = Router.maybeOf(
          context,
        )?.routeInformationProvider?.value;
        final path = routeInfo?.uri.path ?? '';
        final isAdmin =
            path.startsWith(AppRoutes.admin) ||
            path.startsWith(AppRoutes.adminV2) ||
            path.startsWith(AppRoutes.adminDiag);

        Widget body = child!;
        if (!isAdmin) {
          body = BreakReminderHost(
            child: ValueListenableBuilder<bool>(
              valueListenable: ConnectivityWatcher.instance.online,
              child: body,
              builder: (ctx, online, inner) {
                if (online) return inner!;
                final isAr =
                    Localizations.maybeLocaleOf(ctx)?.languageCode == 'ar';
                return _OfflineBanner(isArabic: isAr, child: inner!);
              },
            ),
          );
        }

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(combined),
            disableAnimations: reducedMotion || mediaQuery.disableAnimations,
          ),
          child: body,
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.child, required this.isArabic});
  final Widget child;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(60),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isArabic
                            ? 'لا يوجد اتصال بالإنترنت — قد لا يعمل الصوت أو الخرائط'
                            : "You're offline — audio and maps may not work",
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: ['Amiri', 'NotoColorEmoji'],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
