import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/theme_dark.dart';
import '../core/theme/theme_light.dart';

import '../presentation/state/app_state.dart';
import '../presentation/state/permission_state.dart';
import '../presentation/state/ride_state.dart';

import 'routes.dart';

// (Optional) Fallback use in onGenerateRoute if Routes.map ever misses /wallet


class ZoomigooApp extends StatelessWidget {
  const ZoomigooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => PermissionState()),
        ChangeNotifierProvider(create: (_) => RideState()),
      ],
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            title: 'Zoomigoo',
            debugShowCheckedModeBanner: false,

            // THEME
            theme: buildLightTheme(app.primarySeed),
            darkTheme: buildDarkTheme(app.primarySeed),
            themeMode: app.themeMode,

            // ROUTING (primary)
            initialRoute: Routes.home,
            routes: Routes.map,

            // SAFETY NET: if a route (like /wallet) isn't found in Routes.map,
            // resolve it here so navigation never crashes.
            // onGenerateRoute: (settings) {
            //   // Let app's custom generator handle first (if any)
            //   final generated = Routes.onGenerateRoute(settings);
            //   if (generated != null) return generated;

            //   switch (settings.name) {
            //     case Routes.wallet:
            //       return MaterialPageRoute(
            //         builder: (_) => const WalletScreen(),
            //         settings: settings,
            //       );
            //   }
            //   return null; // fall through to onUnknownRoute
            // },

            onUnknownRoute: Routes.onUnknownRoute,
            navigatorObservers: [Routes.logger],
          );
        },
      ),
    );
  }
}
