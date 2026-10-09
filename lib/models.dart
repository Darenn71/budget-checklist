/// Data models for the Budget Checklist app.
///
/// JSON keys deliberately match the original Python/Tkinter app's
/// `budget_data.json` format (snake_case) so existing data files can be
/// imported directly.
library;

class BillItem {
  String id;
  String name;
  String due; // either a day-of-month ("25"), or a date string
  double amount;
  bool paid;
  double? paidAmount;
  String notes;

  BillItem({
    required this.id,
    required this.name,
    this.due = '',
    this.amount = 0.0,
    this.paid = false,
    this.paidAmount,
    this.notes = '',
  });

  BillItem copy() => BillItem(
        id: id,
        name: name,
        due: due,
        amount: amount,
        paid: paid,
        paidAmount: paidAmount,
        notes: notes,
      );

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      due: json['due']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      paid: json['paid'] == true,
      paidAmount: json['paid_amount'] == null
          ? null
          : _toDouble(json['paid_amount']),
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'due': due,
        'amount': amount,
        'paid': paid,
        'paid_amount': paidAmount,
        'notes': notes,
      };
}

class OwedItem {
  String id;
  String type;
  double amount;
  bool paid;
  String notes;

  OwedItem({
    required this.id,
    required this.type,
    this.amount = 0.0,
    this.paid = false,
    this.notes = '',
  });

  OwedItem copy() => OwedItem(
        id: id,
        type: type,
        amount: amount,
        paid: paid,
        notes: notes,
      );

  factory OwedItem.fromJson(Map<String, dynamic> json) {
    return OwedItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      amount: _toDouble(json['amount']),
      paid: json['paid'] == true,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'paid': paid,
        'notes': notes,
      };
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}
