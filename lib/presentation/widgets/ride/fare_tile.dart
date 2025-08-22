import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/data/models/ride_type.dart';

class FareTile extends StatelessWidget {
  final RideType type;
  final bool selected;
  final VoidCallback onTap;

  const FareTile({super.key, required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(type.label),
      subtitle: Text('ETA ~ ${type.etaMin} min'),
      trailing: Text(Formatters.currency(type.base)),
      leading: Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected ? Theme.of(context).colorScheme.primary.withValues(alpha:0.08) : null,
    );
  }
}
