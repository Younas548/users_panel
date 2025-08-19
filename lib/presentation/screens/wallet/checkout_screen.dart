import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Usage:
/// Navigator.pushNamed(context, '/checkout', arguments: '<checkoutUrl>');
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => setState(() => _loading = false),
          onNavigationRequest: (request) {
            // Agar backend ne deep link set kiya hai e.g. zoomigoo://payment-result
            if (request.url.startsWith('zoomigoo://payment-result')) {
              Navigator.pop(context, request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final startUrl = (args is String && args.isNotEmpty)
        ? args
        : 'https://example.com/'; // fallback for safety

    _controller.loadRequest(Uri.parse(startUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }
}
