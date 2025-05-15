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
  
  // Treasury Bill specific fields
  String? instrumentType;  // 'bill' or 'bond'
  int? period;  // 91 or 180 days for Treasury Bills
  String? isin;
  String? dealSlipNumber;
  double? faceValue;
  double? investmentValue;
  double? yieldPercentage;
  
  // Bond specific fields  
  double? couponRate;
  DateTime? nextCouponDate;
  double? couponValue;
  
  // Additional fields
  String? note;  // Optional note or comment field

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
    // Treasury Bill fields
    this.instrumentType,
    this.period,
    this.isin,
    this.dealSlipNumber,
    this.faceValue,
    this.investmentValue,
    this.yieldPercentage,
    // Bond specific fields    
    this.couponRate,
    this.nextCouponDate,
    this.couponValue,
    this.note,  // Note field
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
      // Treasury Bill fields
      'instrumentType': instrumentType,
      'period': period,
      'isin': isin,
      'dealSlipNumber': dealSlipNumber,
      'faceValue': faceValue,
      'investmentValue': investmentValue,
      'yieldPercentage': yieldPercentage,
      // Bond specific fields
      'couponRate': couponRate,
      'nextCouponDate': nextCouponDate?.millisecondsSinceEpoch,
      'couponValue': couponValue,
      'note': note,  // Note field
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
      // Treasury Bill fields
      instrumentType: map['instrumentType'],
      period: map['period'],
      isin: map['isin'],
      dealSlipNumber: map['dealSlipNumber'],
      faceValue: map['faceValue']?.toDouble(),
      investmentValue: map['investmentValue']?.toDouble(),
      yieldPercentage: map['yieldPercentage']?.toDouble(),
      // Bond specific fields
      couponRate: map['couponRate']?.toDouble(),
      nextCouponDate: map['nextCouponDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['nextCouponDate']) : null,
      couponValue: map['couponValue']?.toDouble(),
      note: map['note'],  // Note field
    );
  }
}