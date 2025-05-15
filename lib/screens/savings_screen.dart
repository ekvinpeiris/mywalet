import 'package:flutter/material.dart';
import 'package:my_wallert/screens/add_account_screen.dart';
import 'package:my_wallert/screens/base_screen.dart';
import '../models/bank_account.dart';
import '../utils/currency_formatter.dart';
import '../controllers/account_controller.dart';
import '../controllers/bank_controller.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final AccountController _accountController = AccountController();
  final BankController _bankController = BankController();
  final Map<String, bool> _deletingStates = {};

  Stream<List<Map<String, dynamic>>> _getSavingsAccounts() {
    String accountType = 'Savings Account';
    return _bankController.getBanks().asyncMap((banks) async {
      List<Map<String, dynamic>> allAccounts = [];
      for (var bank in banks) {
        if (bank.id != null) {
          final accounts = await _accountController.getAccountsByType(bank.id!, accountType).first;
          for (var account in accounts) {
            account.bankId = bank.id;  // Ensure bankId is set
            allAccounts.add({
              'account': account,
              'bankName': bank.bankName,
              'bankId': bank.id,
            });
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
        title: const Text('Delete Account'),
        content: Text('Are you sure you want to delete this savings account?'),
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
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
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
            stream: _getSavingsAccounts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
      
              final savingsAccounts = snapshot.data ?? [];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Savings Accounts',
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
                              settings: const RouteSettings(name: '/savings'),
                              builder: (context) => const AddAccountScreen(selectedAccountType: 0),
                            ),
                          );
                          
                          if (result != null && result['success'] == true) {
                            setState(() {
                              // This will trigger a rebuild and fetch fresh data
                            });
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Savings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Total Savings Summary
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
                            'Total Savings',
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
                                      savingsAccounts.fold(
                                        0.0,
                                        (sum, account) => sum + account['account'].balance,
                                      ),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${savingsAccounts.length} Accounts',
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
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.savings,
                                  color: Colors.green,
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
                  // Savings Accounts List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: savingsAccounts.length,
                    itemBuilder: (context, index) {
                      final accountData = savingsAccounts[index];
                      final account = accountData['account'];
                      final bankName = accountData['bankName'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(
                            Icons.savings,
                            color: Colors.green,
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
                              Text(
                                formatCurrency(account.balance),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
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
                                  onPressed: () async {
                                    // TODO: Implement edit functionality
                                  },
                                ),
                                _deletingStates[account.id] == true
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteAccount(account.bankId!, account.id!, account.accountNumber),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}