class Transaction {
  final String id;
  final String type;
  final String category;
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  // 🟢 Convertir desde JSON (del backend a tu app)
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      amount: (json['amount'] is int)
          ? (json['amount'] as int).toDouble()
          : (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      date: DateTime.parse(json['transactionDate']),
    );
  }

  // 🔵 Convertir a JSON (de tu app al backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
    };
  }
}
