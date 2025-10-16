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
}
