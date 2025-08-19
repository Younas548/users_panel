# user_panel

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.




  static Map<String, WidgetBuilder> get map => {
        permissions: (_) => const PermissionsScreen(),
        home: (_) => const HomeScreen(),
        placeSearch: (_) => const SearchScreen(),
        savedPlaces: (_) => const SavedPlacesScreen(),
        rideOptions: (_) => const RideOptionsScreen(),
        confirmPickup: (_) => const ConfirmPickupScreen(),
        findingDriver: (_) => const FindingDriverScreen(),
        enRoute: (_) => const EnRouteScreen(),
        inRide: (_) => const InRideScreen(),
        completePayment: (_) => const CompletePaymentScreen(),
      };