import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// TODO: apna backend domain yahan set karo (prod/sandbox)
const String backendBase = 'https://YOUR_BACKEND_DOMAIN';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _balance = 0; // TODO: real app me API se load
  final _amountCtl = TextEditingController(text: '500');
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      // Example:
      // final r = await http.get(Uri.parse('$backendBase/wallet/balance'));
      // final data = jsonDecode(r.body) as Map<String, dynamic>;
      // setState(() => _balance = data['balance'] as int? ?? 0);
      setState(() => _balance = _balance); // demo no-op
    } catch (_) {}
  }

  Future<void> _topUp() async {
    final amount = int.tryParse(_amountCtl.text.trim()) ?? 0;
    if (amount <= 0) {
      _snack('Enter a valid amount');
      return;
    }
    final orderId = 'topup-${DateTime.now().millisecondsSinceEpoch}';

    setState(() => _busy = true);
    try {
      // 1) create hosted checkout URL from backend
      final r = await http.post(
        Uri.parse('$backendBase/create-order'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'amount': amount,                          // PKR
          'orderId': orderId,                        // your unique id
          'returnUrl': 'zoomigoo://payment-result',  // deep link (optional)
        }),
      );
      if (r.statusCode != 200) throw Exception('create-order failed');
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      final checkoutUrl = body['checkoutUrl'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('No checkoutUrl');
      }

      // 2) open hosted checkout (JazzCash/Easypaisa via your backend config)
      final ok = await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.inAppWebView);
      if (!ok) throw Exception('Could not open checkout');

      // 3) verify after user returns/close
      final vr = await http.get(Uri.parse('$backendBase/verify-order?orderId=$orderId'));
      final verified = vr.statusCode == 200 &&
          ((jsonDecode(vr.body) as Map<String, dynamic>)['paid'] == true);

      if (verified) {
        _snack('Top-up successful');
        await _loadBalance();
        if (!mounted) return;
        // Optional: open receipt screen if you have it registered
        // Navigator.pushNamed(context, Routes.paymentReceipt, arguments: {
        //   'orderId': orderId,
        //   'amountPkr': amount,
        //   'methodLabel': (jsonDecode(vr.body) as Map<String, dynamic>)['method'] ?? 'Wallet',
        //   'dateTime': DateTime.now(),
        // });
      } else {
        _snack('Payment not verified');
      }
    } catch (e) {
      _snack('Payment error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Wallet & Payments')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: cs.surfaceVariant.withOpacity(0.4),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Current balance'),
                subtitle: Text('PKR $_balance'),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadBalance,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to add (PKR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [200, 500, 1000, 2000].map((v) {
                  return ActionChip(
                    label: Text('PKR $v'),
                    onPressed: () => _amountCtl.text = '$v',
                  );
                }).toList(),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : _topUp,
                icon: _busy
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Add money (JazzCash / Easypaisa)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
