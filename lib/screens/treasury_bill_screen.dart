import 'package:flutter/material.dart';
import 'package:my_wallert/screens/base_screen.dart';
import '../models/bank_account.dart';
import '../utils/currency_formatter.dart';
import '../controllers/account_controller.dart';
import '../controllers/bank_controller.dart';
import 'add_account_screen.dart';

class TreasuryBillScreen extends StatefulWidget {
  const TreasuryBillScreen({super.key});

  @override
  State<TreasuryBillScreen> createState() => _TreasuryBillScreenState();
}

class _TreasuryBillScreenState extends State<TreasuryBillScreen> {
  final AccountController _accountController = AccountController();
  final BankController _bankController = BankController();
  final Map<String, bool> _deletingStates = {};

  Stream<List<Map<String, dynamic>>> _getTreasuryBillAccounts() {
    String accountType = 'Treasury Bill';
    return _bankController.getBanks().asyncMap((banks) async {
      List<Map<String, dynamic>> allAccounts = [];
      for (var bank in banks) {
        if (bank.id != null && bank.id!.isNotEmpty) {
          final accounts = await _accountController.getAccountsByType(bank.id!, accountType).first;
          for (var account in accounts) {
            if (account != null) {
              allAccounts.add({
                'account': account,
                'bankName': bank.bankName ?? '',
                'bankId': bank.id,
              });
            }
          }
        }
      }
      return allAccounts;
    });
  }

  Future<void> _deleteAccount(String? bankId, String? accountId, String accountNumber) async {
    if (bankId == null || accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Unable to delete account due to missing information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Treasury Bill'),
        content: Text('Are you sure you want to delete this treasury bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _deletingStates[accountId] = true;
      });
      
      try {
        await _accountController.deleteAccount(bankId, accountId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Treasury Bill deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting treasury bill: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _deletingStates.remove(accountId);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getTreasuryBillAccounts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
      
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
      
              final treasuryBills = snapshot.data ?? [];
      
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Treasury Bills',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result =  await Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(name: '/treasury-bill'),
                              builder: (context) => const AddAccountScreen(selectedAccountType: 2),
                            ),
                          );
      
                          if (result != null && result['success'] == true) {
                            setState(() {
                              // This will trigger a rebuild and fetch fresh data
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add T-Bill'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total Treasury Bills Summary
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    color: Colors.white,
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Treasury Bills',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatCurrency(
                                      treasuryBills.fold(
                                        0.0,
                                            (sum, account) {
                                          final tbill = account['account'] as BankAccount;
                                          // Only include non-matured bills in total
                                          if (tbill.maturityDate != null && tbill.maturityDate!.isAfter(DateTime.now())) {
                                            return sum + tbill.balance;
                                          }
                                          return sum;
                                        },
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${treasuryBills.where((tb) => (tb['account'] as BankAccount).maturityDate?.isAfter(DateTime.now()) ?? false).length} Active Bills',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.description,
                                  color: Colors.indigo,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder: (context) {
                      // Group treasury bills by maturity status
                      final activeBills = treasuryBills.where((tb) =>
                      (tb['account'] as BankAccount).maturityDate?.isAfter(DateTime.now()) ?? false
                      ).toList();
      
                      final maturedBills = treasuryBills.where((tb) =>
                      (tb['account'] as BankAccount).maturityDate?.isAfter(DateTime.now()) == false
                      ).toList();
      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (activeBills.isNotEmpty) ...[
                            const Text(
                              'Active Treasury Bills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeBills.length,
                              itemBuilder: (context, index) {
                                final accountData = activeBills[index];
                                final account = accountData['account'];
                                final bankName = accountData['bankName'];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.description,
                                      color: Colors.indigo,
                                      size: 32,
                                    ),
                                    title: Text(account.accountNumber),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bankName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (account.yieldPercentage != null)
                                              Text(
                                                'Yield: ${account.yieldPercentage}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            if (account.yieldPercentage != null && account.period != null)
                                              Text(
                                                ' • ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            if (account.period != null)
                                              Text(
                                                '${account.period} days',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (account.startDate != null)
                                          Text(
                                            'Start: ${account.startDate!.day}/${account.startDate!.month}/${account.startDate!.year}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        if (account.maturityDate != null)
                                          Text(
                                            'Maturity: ${account.maturityDate!.day}/${account.maturityDate!.month}/${account.maturityDate!.year}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),                                      if (account.faceValue != null)
                                          Text(
                                            'Face Value: ${formatCurrency(account.faceValue!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        if (account.investmentValue != null)
                                          Text(
                                            'Investment: ${formatCurrency(account.investmentValue!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        Text(
                                          formatCurrency(account.balance),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              // TODO: Implement edit functionality
                                            },
                                          ),
                                          _deletingStates[account.id] == true
                                              ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                                            ),
                                          )
                                              : IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteAccount(account.bankId, account.id, account.accountNumber),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
      
                          // Matured Treasury Bills Section
                          if (maturedBills.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            const Text(
                              'Matured Treasury Bills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: maturedBills.length,
                              itemBuilder: (context, index) {
                                final accountData = maturedBills[index];
                                final account = accountData['account'];
                                final bankName = accountData['bankName'];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  color: Colors.grey[100], // Lighter background for matured bills
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.grey,
                                      size: 32,
                                    ),
                                    title: Row(
                                      children: [
                                        Text(account.accountNumber),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'Matured',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bankName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            if (account.yieldPercentage != null)
                                              Text(
                                                'Yield: ${account.yieldPercentage}%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            if (account.yieldPercentage != null && account.period != null)
                                              Text(
                                                ' • ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            if (account.period != null)
                                              Text(
                                                '${account.period} days',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (account.maturityDate != null)
                                          Text(
                                            'Matured on: ${account.maturityDate!.day}/${account.maturityDate!.month}/${account.maturityDate!.year}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),                                      if (account.faceValue != null)
                                          Text(
                                            'Face Value: ${formatCurrency(account.faceValue!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        if (account.investmentValue != null)
                                          Text(
                                            'Investment: ${formatCurrency(account.investmentValue!)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        Text(
                                          formatCurrency(account.balance),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.grey),
                                            onPressed: () {
                                              // TODO: Implement edit functionality
                                            },
                                          ),
                                          _deletingStates[account.id] == true
                                              ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                            ),
                                          )
                                              : IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.grey),
                                            onPressed: () => _deleteAccount(account.bankId, account.id, account.accountNumber),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ); // Removed the extra parenthesis and semicolon from here
  }
}