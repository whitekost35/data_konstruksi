class Transaction {
  final String id;
  final String periodId;
  final String title;
  final double amount;
  final String date;
  final String? category;
  final String? note;

  Transaction({
    required this.id,
    required this.periodId,
    required this.title,
    required this.amount,
    required this.date,
    this.category,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'periodId': periodId,
      'title': title,
      'amount': amount,
      'date': date,
      'category': category,
      'note': note,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id']?.toString() ?? '',
      periodId: map['periodId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: map['date'] ?? '',
      category: map['category'],
      note: map['note'],
    );
  }
}

extension TransactionSmartCategory on Transaction {
  bool matchesCategory(String searchCat) {
    final txCat = category?.toLowerCase().trim() ?? 'lain-lain';
    final txTitle = title.toLowerCase().trim();
    final target = searchCat.toLowerCase().trim();

    if (target == 'ac') {
      return txCat == 'ac' || 
             txCat.contains('ac') || 
             RegExp(r'\bac\b').hasMatch(txTitle) ||
             txTitle.startsWith('ac');
    }
    if (target == 'puing') {
      return txCat.contains('puing') || txTitle.contains('puing');
    }
    if (target == 'kramik' || target == 'keramik') {
      return txCat.contains('kramik') ||
          txCat.contains('keramik') ||
          txTitle.contains('kramik') ||
          txTitle.contains('keramik');
    }
    if (target == 'gondes') {
      return txCat == 'gondes';
    }
    if (target == 'bumimas_belanja') return txCat == 'bumimas_belanja';
    if (target == 'bumimas_lunas') return txCat == 'bumimas_lunas';

    if (target == 'lain-lain') {
      return !matchesCategory('ac') &&
          !matchesCategory('puing') &&
          !matchesCategory('kramik') &&
          !matchesCategory('gondes') &&
          !txCat.startsWith('bumimas');
    }

    return txCat == target;
  }
}
