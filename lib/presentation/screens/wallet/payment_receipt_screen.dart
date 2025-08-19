import 'package:flutter/material.dart';

class PaymentReceiptArgs {
  final String orderId;
  final int amountPkr;
  final String methodLabel;
  final DateTime dateTime;
  PaymentReceiptArgs({
    required this.orderId,
    required this.amountPkr,
    required this.methodLabel,
    required this.dateTime,
  });
}

class PaymentReceiptScreen extends StatelessWidget {
  const PaymentReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final a = ModalRoute.of(context)!.settings.arguments as PaymentReceiptArgs;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment successful ✅', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _row('Order ID', a.orderId),
                _row('Amount', 'PKR ${a.amountPkr}'),
                _row('Method', a.methodLabel),
                _row('Date', a.dateTime.toString()),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(k), Text(v, style: const TextStyle(fontWeight: FontWeight.w700))],
    ),
  );
}
