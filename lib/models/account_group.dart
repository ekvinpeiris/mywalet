import 'bank_account.dart';

class AccountGroup {
  final String name;
  final List<BankAccount> accounts;
  bool isExpanded;

  AccountGroup({
    required this.name,
    required this.accounts,
    this.isExpanded = false,
  });

  double get totalBalance => accounts.fold(0, (sum, account) => sum + account.balance);
}
