enum WorkerRole {
  tukang,
  kenek,
  borongan;

  double get defaultWage {
    switch (this) {
      case WorkerRole.tukang: return 200000.0;
      case WorkerRole.kenek: return 150000.0;
      case WorkerRole.borongan: return 0.0;
    }
  }

  String get label {
    switch (this) {
      case WorkerRole.tukang: return 'TUKANG';
      case WorkerRole.kenek: return 'KENEK';
      case WorkerRole.borongan: return 'BORONGAN';
    }
  }
}

class Worker {
  final String id;
  final String name;
  final WorkerRole role;
  final double baseWage;
  final bool isActive;
  final int orderIndex; // New

  Worker({
    required this.id,
    required this.name,
    required this.role,
    required this.baseWage,
    this.isActive = true,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name.toUpperCase(),
      'base_wage': baseWage,
      'is_active': isActive,
      'order_index': orderIndex,
    };
  }

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      role: _parseRole(map['role']),
      baseWage: (map['base_wage'] ?? 0.0).toDouble(),
      isActive: map['is_active'] ?? true,
      orderIndex: map['order_index'] ?? 0,
    );
  }

  static WorkerRole _parseRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'KENEK': return WorkerRole.kenek;
      case 'BORONGAN': return WorkerRole.borongan;
      default: return WorkerRole.tukang;
    }
  }
}
