import 'package:flutter/material.dart';
import '../models/bank_account.dart';
import '../utils/currency_formatter.dart';
import '../controllers/account_controller.dart';
import '../controllers/bank_controller.dart';
import 'add_account_screen.dart';

class FixedDepositScreen extends StatefulWidget {
  const FixedDepositScreen({super.key});

  @override
  State<FixedDepositScreen> createState() => _FixedDepositScreenState();
}

class _FixedDepositScreenState extends State<FixedDepositScreen> {
  final AccountController _accountController = AccountController();
  final BankController _bankController = BankController();
  Map<String, bool> _deletingStates = {};
  
  Stream<List<Map<String, dynamic>>> _getFixedDepositAccounts() {
    String accountType = 'Fixed Deposit';
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
        title: const Text('Delete Fixed Deposit'),
        content: Text('Are you sure you want to delete this fixed deposit account?'),
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
              content: Text('Fixed Deposit deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting fixed deposit: $e'),
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

  String _getInterestFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'on_maturity':
        return 'On Maturity';
      case 'monthly':
        return 'Monthly';
      case 'annually':
        return 'Annually';
      default:
        return frequency;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getFixedDepositAccounts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final fixedDeposits = snapshot.data ?? [];
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fixed Deposits',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddAccountScreen(selectedAccountType: 1),
                          ),
                        );
                        
                        if (result != null && result['success'] == true) {
                          setState(() {
                            // This will trigger a rebuild and fetch fresh data
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add FD'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Total Fixed Deposits Summary
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
                          'Total Fixed Deposits',
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
                                    fixedDeposits.fold(
                                      0.0,
                                      (sum, account) => sum + account['account'].balance,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${fixedDeposits.length} Accounts',
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
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.orange,
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
                // Fixed Deposits List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fixedDeposits.length,
                  itemBuilder: (context, index) {
                    final accountData = fixedDeposits[index];
                    final account = accountData['account'];
                    final bankName = accountData['bankName'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(
                          Icons.lock,
                          color: Colors.orange,
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
                                if (account.interestRate != null)
                                  Text(
                                    'Rate: ${account.interestRate}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (account.interestRate != null && account.interestPayoutFrequency != null)
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (account.interestPayoutFrequency != null)
                                  Text(
                                    '${_getInterestFrequencyLabel(account.interestPayoutFrequency!)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (account.durationInMonths != null)
                                  Text(
                                    ' • ${account.durationInMonths} months',
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
                              ),
                            Text(
                              formatCurrency(account.balance),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
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
            );
          },
        ),
      ),
    );
  }
}