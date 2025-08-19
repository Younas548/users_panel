class RideType {
  final String code;
  final String label;
  final num base;
  final num perKm;
  final int etaMin;

  RideType({required this.code, required this.label, required this.base, required this.perKm, required this.etaMin});

  factory RideType.fromJson(Map<String, dynamic> j) => RideType(
    code: j['code'], label: j['label'], base: j['base'], perKm: j['per_km'], etaMin: j['eta_min'],
  );
}
