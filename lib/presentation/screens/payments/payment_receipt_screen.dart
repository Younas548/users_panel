import 'package:flutter/material.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final String orderId;
  final int amountPkr;
  final String methodLabel; // JazzCash / Easypaisa / Card / Wallet
  final DateTime dateTime;

  const PaymentReceiptScreen({
    super.key,
    required this.orderId,
    required this.amountPkr,
    required this.methodLabel,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: cs.surfaceVariant.withValues(alpha:0.5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 8),
                const Text('Payment Successful', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                _row('Amount', 'PKR $amountPkr'),
                _row('Method', methodLabel),
                _row('Order ID', orderId),
                _row('Date', '${dateTime.toLocal()}'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share / Save'),
                    onPressed: () {
                      // TODO: implement share/pdf
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Text(v),
        ],
      ),
    );
  }
}
