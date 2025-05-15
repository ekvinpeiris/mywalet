import 'package:flutter/material.dart';
import 'package:my_wallert/screens/base_screen.dart';
import 'package:my_wallert/screens/edit_account_screen.dart';
import '../models/bank_account.dart';
import '../utils/currency_formatter.dart';
import '../controllers/account_controller.dart';
import '../controllers/bank_controller.dart';
import '../services/csv_import_service.dart'; // Import the service
import 'add_account_screen.dart';

class FixedDepositScreen extends StatefulWidget {
  const FixedDepositScreen({super.key});

  @override
  State<FixedDepositScreen> createState() => _FixedDepositScreenState();
}

class _FixedDepositScreenState extends State<FixedDepositScreen> {
  final AccountController _accountController = AccountController();
  final BankController _bankController = BankController();
  final CsvImportService _csvImportService = CsvImportService(); // Instantiate the service
  Map<String, bool> _deletingStates = {};
  bool _isImporting = false; // State variable for import loading

  Stream<List<Map<String, dynamic>>> _getFixedDepositAccounts() {
    String accountType = 'Fixed Deposit';
    return _bankController.getBanks().asyncMap((banks) async {
      List<Map<String, dynamic>> allAccounts = [];
      for (var bank in banks) {
        if (bank.id != null && bank.id!.isNotEmpty) {  // Check for non-empty string ID
          final accounts = await _accountController.getAccountsByType(bank.id!, accountType).first;
          for (var account in accounts) {
            if (account != null) {  // Ensure account exists
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

  Future<void> _handleCsvImport() async {
    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _csvImportService.importFixedDepositsFromCsv();

      if (!mounted) return; // Check if the widget is still in the tree

      // Prepare result message
      String message = 'CSV Import Complete:\n'
                       '- Total Rows Processed: ${result.totalRows}\n'
                       '- Imported Successfully: ${result.importedCount}\n'
                       '- Skipped (Duplicates): ${result.skippedDuplicateCount}\n'
                       '- Skipped (Errors): ${result.skippedErrorCount}';

      List<Widget> errorWidgets = [];
      if (result.errors.isNotEmpty) {
        message += '\n\nErrors Encountered:';
        errorWidgets = result.errors.map((e) => Text(e, style: const TextStyle(fontSize: 12))).toList();
      }

      // Show results dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Results'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
                if (errorWidgets.isNotEmpty) const SizedBox(height: 10),
                if (errorWidgets.isNotEmpty) const Text('Error Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (errorWidgets.isNotEmpty) ...errorWidgets,
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );

      // Refresh the list if any accounts were imported
      if (result.importedCount > 0) {
        setState(() {
          // Trigger rebuild to fetch fresh data
        });
      }

    } catch (e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('An unexpected error occurred during import: $e'),
           backgroundColor: Colors.red,
         ),
       );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  // Separate active and matured deposits
  List<Map<String, dynamic>> _getActiveDeposits(List<Map<String, dynamic>> deposits) {
    final now = DateTime.now();
    return deposits.where((d) {
      final account = d['account'] as BankAccount;
      return account.maturityDate != null && account.maturityDate!.isAfter(now);
    }).toList();
  }

  List<Map<String, dynamic>> _getMaturedDeposits(List<Map<String, dynamic>> deposits) {
    final now = DateTime.now();
    return deposits.where((d) {
      final account = d['account'] as BankAccount;
      return account.maturityDate != null && !account.maturityDate!.isAfter(now);
    }).toList();
  }

  String _getInterestFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'maturity':
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
    return BaseScreen(
      child: SingleChildScrollView(
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
                      Row( // Wrap buttons in a Row
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           // Import Button
                           _isImporting
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton( // Use IconButton for space
                                  icon: const Icon(Icons.upload_file),
                                  tooltip: 'Import from CSV',
                                  onPressed: _handleCsvImport, // Call the import handler
                                ),
                           const SizedBox(width: 8), // Spacing between buttons
                           // Add Button
                           ElevatedButton.icon(
                            onPressed: _isImporting ? null : () async { // Disable Add button during import
                              final result =  await Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  settings: const RouteSettings(name: '/fixed-deposits'),
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
                      )
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
                  ),                  const SizedBox(height: 24),
                  // Active Fixed Deposits Section
                  const Text(
                    'Active Fixed Deposits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getActiveDeposits(fixedDeposits).length,                    itemBuilder: (context, index) {
                      final accountData = _getActiveDeposits(fixedDeposits)[index];
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
                              children: [                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditAccountScreen(
                                          bankId: account.bankId!,
                                          account: account,
                                        ),
                                      ),
                                    );

                                    if (result != null && result['success'] == true) {
                                      setState(() {
                                        // Trigger rebuild to fetch fresh data
                                      });
                                    }
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
                  // Matured Fixed Deposits Section
                  if (_getMaturedDeposits(fixedDeposits).isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Matured Fixed Deposits',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _getMaturedDeposits(fixedDeposits).length,
                      itemBuilder: (context, index) {
                        final accountData = _getMaturedDeposits(fixedDeposits)[index];
                        final account = accountData['account'];
                        final bankName = accountData['bankName'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.grey[100], // Differentiate matured deposits visually
                          child: ListTile(
                            leading: const Icon(
                              Icons.lock_open,  // Different icon for matured deposits
                              color: Colors.grey,
                              size: 32,
                            ),
                            title: Text(
                              account.accountNumber,
                              style: const TextStyle(color: Colors.grey),
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
                                    'Matured: ${account.maturityDate!.day}/${account.maturityDate!.month}/${account.maturityDate!.year}',
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
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditAccountScreen(
                                            bankId: account.bankId!,
                                            account: account,
                                          ),
                                        ),
                                      );

                                      if (result != null && result['success'] == true) {
                                        setState(() {
                                          // Trigger rebuild to fetch fresh data
                                        });
                                      }
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
        ),
      ),
    );
  }
}
