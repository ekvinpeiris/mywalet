class BankAccount {
  String? id;
  String? bankId;
  String accountNumber;
  String accountType;
  double balance;
  String? userId;
  DateTime? startDate;
  DateTime? maturityDate;
  double? interestRate;
  int? durationInMonths;
  String? interestPayoutFrequency;  // 'maturity', 'monthly', 'annually'

  BankAccount({
    this.id,
    this.bankId,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    this.userId,
    this.startDate,
    this.maturityDate,
    this.interestRate,
    this.durationInMonths,
    this.interestPayoutFrequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankId': bankId,
      'accountNumber': accountNumber,
      'accountType': accountType,
      'balance': balance,
      'userId': userId,
      'startDate': startDate?.millisecondsSinceEpoch,
      'maturityDate': maturityDate?.millisecondsSinceEpoch,
      'interestRate': interestRate,
      'durationInMonths': durationInMonths,
      'interestPayoutFrequency': interestPayoutFrequency,
    };
  }

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
      id: map['id'],
      bankId: map['bankId'],
      accountNumber: map['accountNumber'] ?? '',
      accountType: map['accountType'] ?? '',
      balance: map['balance']?.toDouble() ?? 0.0,
      userId: map['userId'],
      startDate: map['startDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startDate']) : null,
      maturityDate: map['maturityDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['maturityDate']) : null,
      interestRate: map['interestRate']?.toDouble(),
      durationInMonths: map['durationInMonths'],
      interestPayoutFrequency: map['interestPayoutFrequency'],
    );
  }
}