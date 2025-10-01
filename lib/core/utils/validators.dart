class Validators {
  static String? requiredField(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName} is required';
    }
    return null;
  }

  static String? studentNumber(String? value) {
    final required = requiredField(value, fieldName: 'Student Number');
    if (required != null) {
      return required;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value!.trim())) {
      return 'Digits only';
    }
    return null;
  }
}
