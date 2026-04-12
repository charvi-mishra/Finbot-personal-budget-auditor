class UserModel {
  final String uid;
  final String name;
  final String email;
  final String country;
  final String occupation;
  final double? monthlyIncome;
  final double? currentSavings;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.country,
    required this.occupation,
    this.monthlyIncome,
    this.currentSavings,
    required this.createdAt,
  });

  bool get isUnemployed =>
      occupation.toLowerCase().contains('unemployed') ||
      occupation.toLowerCase().contains('student') ||
      occupation.toLowerCase() == 'none' ||
      occupation.toLowerCase().contains('retired');

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      country: map['country'] ?? '',
      occupation: map['occupation'] ?? '',
      monthlyIncome: (map['monthlyIncome'] as num?)?.toDouble(),
      currentSavings: (map['currentSavings'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'country': country,
        'occupation': occupation,
        'monthlyIncome': monthlyIncome,
        'currentSavings': currentSavings,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    double? currentSavings,
    double? monthlyIncome,
  }) =>
      UserModel(
        uid: uid,
        name: name,
        email: email,
        country: country,
        occupation: occupation,
        monthlyIncome: monthlyIncome ?? this.monthlyIncome,
        currentSavings: currentSavings ?? this.currentSavings,
        createdAt: createdAt,
      );
}
