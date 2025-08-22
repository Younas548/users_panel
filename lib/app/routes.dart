import 'package:flutter/material.dart';

// ENTRY / CORE
//import '../presentation/screens/permissions/permissions_screen.dart';
import '../presentation/screens/homes/home_screen.dart';

// PLACES
import '../presentation/screens/places/search_screen.dart';
import '../presentation/screens/places/saved_places_screen.dart';

// RIDES
import '../presentation/screens/rides/ride_options/ride_options_screen.dart';
import '../presentation/screens/rides/confirm_pickup/confirm_pickup_screen.dart';
import '../presentation/screens/rides/finding_driver/finding_driver_screen.dart';
import '../presentation/screens/rides/en_route/en_route_screen.dart';
import '../presentation/screens/rides/in_ride/in_ride_screen.dart';
import '../presentation/screens/rides/complete_payment/complete_payment_screen.dart';

// PHASE-2
import '../presentation/screens/history/history_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/support/support_screen.dart';
import '../presentation/screens/safety/safety_screen.dart';

// <- make sure file exists

class Routes {
  // core
  static const permissions = '/permissions';
  static const home        = '/home';
  static const root        = '/';

  // places
  static const placeSearch   = '/places/search';
  static const savedPlaces   = '/places/saved';

  // ride
  static const rideOptions     = '/ride/options';
  static const confirmPickup   = '/ride/confirm';
  static const findingDriver   = '/ride/finding';
  static const enRoute         = '/ride/en-route';
  static const inRide          = '/ride/in-ride';
  static const completePayment = '/ride/complete';

  // phase-2
  static const history  = '/history';
  static const profile  = '/profile';
  static const settings = '/settings';
  static const support  = '/support';
  static const safety   = '/safety';

  // wallet
  static const wallet          = '/wallet';
  static const checkout        = '/checkout';
  static const paymentReceipt  = '/payment-receipt';

  // ---- Simple map: only arg-less screens yahan rakho ----
  static final Map<String, WidgetBuilder> map = {
    // core
   //permissions: (_) => const PermissionsScreen(),
    home:        (_) => const HomeScreen(),
    root:        (_) => const HomeScreen(), // alias

    // places
    placeSearch: (_) => const SearchScreen(),
    savedPlaces: (_) => const SavedPlacesScreen(),

    // ride
    rideOptions:     (_) => const RideOptionsScreen(),
    confirmPickup:   (_) => const ConfirmPickupScreen(),
    findingDriver:   (_) => const FindingDriverScreen(),
    enRoute:         (_) => const EnRouteScreen(),
    inRide:          (_) => const InRideScreen(),
    completePayment: (_) => const CompletePaymentScreen(),

    // phase-2
    history:  (_) => const RideHistoryScreen(),
    profile:  (_) => const ProfileScreen(),
    settings: (_) => const SettingsScreen(),
    support:  (_) => const SupportScreen(),
    safety:   (_) => const SafetyScreen(),

    // wallet (arg-less)
   // wallet: (_) => const WalletScreen(),
    // ⚠️ DO NOT put checkout/paymentReceipt here (they need arguments via settings)
  };

  // ---- Argument-based routes yahan se banao ----
  // static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  //   switch (settings.name) {
  //     case checkout:
  //       // CheckoutScreen args screen ke andar ModalRoute se liye ja rahe hain,
  //       // is liye yahan sirf settings pass kar do.
  //       return MaterialPageRoute(
  //         builder: (_) => const CheckoutScreen(),
  //         settings: settings,
  //       );

  //     case paymentReceipt:
  //       // Agar aapki PaymentReceiptScreen constructor me args chahiye,
  //       // screen ke andar ModalRoute.of(context)!.settings.arguments se le lo.
  //       return MaterialPageRoute(
  //         builder: (_) => const PaymentReceiptScreen(),
  //         settings: settings,
  //       );
  //   }
  //   return null; // let onUnknownRoute handle unknowns
  // }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    debugPrint('⚠️ Unknown route: ${settings.name}');
    return MaterialPageRoute(builder: (_) => const HomeScreen());
  }

  // Optional route logger
  static final NavigatorObserver logger = _RouteLogger();
}

class _RouteLogger extends NavigatorObserver {
  @override
  void didPush(Route route, Route<dynamic>? previousRoute) {
    debugPrint('➡️ PUSH ${route.settings.name}');
    super.didPush(route, previousRoute);
  }
}
