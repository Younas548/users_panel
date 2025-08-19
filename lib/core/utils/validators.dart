class Validators {
  static String? notEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }
}
