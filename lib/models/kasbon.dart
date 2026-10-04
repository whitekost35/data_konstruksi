class GlobalKasbonEntry {
  final String id;
  final String weekStartDate;
  final String date;
  final String description;
  final double amount;

  GlobalKasbonEntry({
    required this.id,
    required this.weekStartDate,
    required this.date,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'week_start_date': weekStartDate,
      'date': date,
      'description': description,
      'amount': amount,
    };
  }

  factory GlobalKasbonEntry.fromMap(Map<String, dynamic> map) {
    return GlobalKasbonEntry(
      id: map['id']?.toString() ?? '',
      weekStartDate: map['week_start_date'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}

class PrivateKasbonEntry {
  final String id;
  final String workerId;
  final String date;
  final String description;
  final double loanAmount;
  final double paymentAmount;
  final String note;

  PrivateKasbonEntry({
    required this.id,
    required this.workerId,
    required this.date,
    required this.description,
    this.loanAmount = 0.0,
    this.paymentAmount = 0.0,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'worker_id': workerId,
      'date': date,
      'description': description,
      'loan_amount': loanAmount,
      'payment_amount': paymentAmount,
      'note': note,
    };
  }

  factory PrivateKasbonEntry.fromMap(Map<String, dynamic> map) {
    return PrivateKasbonEntry(
      id: map['id']?.toString() ?? '',
      workerId: map['worker_id'] ?? '',
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      loanAmount: (map['loan_amount'] ?? 0.0).toDouble(),
      paymentAmount: (map['payment_amount'] ?? 0.0).toDouble(),
      note: map['note'] ?? '',
    );
  }
}
