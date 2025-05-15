import 'package:flutter/material.dart';
import 'package:my_wallert/screens/add_bank.dart';
import 'package:my_wallert/screens/base_screen.dart';
import '../controllers/bank_controller.dart';
import '../models/bank.dart';

class BankScreen extends StatefulWidget {

  const BankScreen({
    super.key,
  });

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  final BankController _bankController = BankController();
  Stream<List<Bank>>? _banksStream;
  Map<String, bool> _deletingStates = {};

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  void _loadBanks() {
    setState(() {
      _banksStream = _bankController.getBanks();
    });
  }

  IconData _getAccountIcon(String accountName) {
    if (accountName.contains('Savings')) return Icons.savings;
    if (accountName.contains('Fixed Deposit')) return Icons.lock;
    if (accountName.contains('Current')) return Icons.account_balance;
    return Icons.account_balance_wallet;
  }

  Color _getAccountColor(String accountName) {
    if (accountName.contains('Savings')) return Colors.green;
    if (accountName.contains('Fixed Deposit')) return Colors.orange;
    if (accountName.contains('Current')) return Colors.purple;
    return Colors.blue;
  }

  Future<void> _deleteBank(String bankId, String bankName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank'),
        content: Text('Are you sure you want to delete $bankName? This will delete all associated accounts.'),
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
        _deletingStates[bankId] = true;
      });

      try {
        await _bankController.deleteBank(bankId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting bank: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _deletingStates.remove(bankId);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Banks',
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
                          builder: (context) => const AddBank(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Bank'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StreamBuilder<List<Bank>>(
                stream: _banksStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
      
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
      
                  final banks = snapshot.data ?? [];
                  
                  if (banks.isEmpty) {
                    return const Center(
                      child: Text('No banks added yet'),
                    );
                  }
      
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: banks.length,
                    itemBuilder: (context, index) {
                      final bank = banks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(Icons.account_balance, color: Colors.blue),
                          title: Text(
                            bank.bankName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  // TODO: Implement edit bank
                                },
                              ),
                              _deletingStates[bank.id!] == true
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _deleteBank(bank.id!, bank.bankName),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}