class BuilderValidation {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const BuilderValidation({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  factory BuilderValidation.initial() {
    return const BuilderValidation(
      isValid: true,
      errors: [],
      warnings: [],
    );
  }
}