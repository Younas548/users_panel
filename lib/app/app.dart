import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_dark.dart';
import '../core/theme/theme_light.dart';

import '../presentation/state/app_state.dart';
import '../presentation/state/notification_state.dart';
import '../presentation/state/permission_state.dart';
import '../presentation/state/ride_state.dart';

import 'routes.dart';

/// ---- Global pressed-overlay/elevation + enforced colors (WidgetStateProperty) ----
ThemeData _withGlobalButtonEffects(ThemeData base) {
  final cs = base.colorScheme;

  return base.copyWith(
    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(cs.primary),
        foregroundColor: WidgetStatePropertyAll(cs.onPrimary),
        animationDuration: const Duration(milliseconds: 140),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? cs.onPrimary.withValues(alpha: .30) // more visible press
              : null,
        ),
        elevation: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed) ? 0 : 1,
        ),
      ),
    ),

    // FilledButton (primary CTA)
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(cs.primary),
        foregroundColor: WidgetStatePropertyAll(cs.onPrimary),
        animationDuration: const Duration(milliseconds: 140),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? cs.onPrimary.withValues(alpha: .20)
              : null,
        ),
      ),
    ),

    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(cs.primary),
        animationDuration: const Duration(milliseconds: 140),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? cs.primary.withValues(alpha: .18)
              : null,
        ),
      ),
    ),

    // IconButton
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(cs.primary),
        animationDuration: const Duration(milliseconds: 120),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? cs.primary.withValues(alpha: .19)
              : null,
        ),
      ),
    ),
  );
}

/// App
class ZoomigooApp extends StatelessWidget {
  const ZoomigooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => PermissionState()),
        ChangeNotifierProvider(create: (_) => RideState()),
        ChangeNotifierProvider(create: (_) => NotificationState()..load()),
      ],
      child: Consumer<AppState>(
        builder: (context, app, _) {
          final ThemeData light = _withGlobalButtonEffects(buildLightTheme(app.primarySeed));
          final ThemeData dark  = _withGlobalButtonEffects(buildDarkTheme(app.primarySeed));

          return MaterialApp(
            title: 'Zoomigoo',
            debugShowCheckedModeBanner: false,
            theme: light,
            darkTheme: dark,
            themeMode: app.themeMode,
            initialRoute: Routes.home,
            routes: Routes.map,
            onUnknownRoute: Routes.onUnknownRoute,
            navigatorObservers: [Routes.logger],
          );
        },
      ),
    );
  }
}
