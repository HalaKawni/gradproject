class ChildSignupProfile {
  final int age;
  final String ageGroup;
  final String gender;

  const ChildSignupProfile({
    required this.age,
    required this.ageGroup,
    required this.gender,
  });
}

String ageGroupForAge(int age) {
  if (age < 6) {
    return 'under_6';
  }
  if (age <= 8) {
    return '6_8';
  }
  if (age <= 11) {
    return '9_11';
  }
  if (age <= 14) {
    return '12_14';
  }
  if (age <= 17) {
    return '15_17';
  }
  return '18_plus';
}
