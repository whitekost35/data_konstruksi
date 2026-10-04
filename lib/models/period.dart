class ProjectPeriod {
  final String id;
  final String name;
  final String dateRange;
  final double totalAmount;
  final bool isActive;
  final String colorHex;

  ProjectPeriod({
    required this.id,
    required this.name,
    required this.dateRange,
    this.totalAmount = 0.0,
    this.isActive = false,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateRange': dateRange,
      'totalAmount': totalAmount,
      'isActive': isActive,
      'colorHex': colorHex,
    };
  }

  factory ProjectPeriod.fromMap(Map<String, dynamic> map) {
    return ProjectPeriod(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dateRange: map['dateRange'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? false,
      colorHex: map['colorHex'] ?? '#000000',
    );
  }
}
