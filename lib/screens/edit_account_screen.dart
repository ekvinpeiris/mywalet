import 'package:flutter/material.dart';
import '../models/account_group.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_navigation.dart';

class EditAccountScreen extends StatefulWidget {
  final AccountGroup group;

  const EditAccountScreen({
    super.key,
    required this.group,
  });

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late String _selectedAccountType;

  final List<String> _accountTypes = [
    'Savings Account',
    'Fixed Deposit',
    'Checking Account',
    'Current Account',
    'Recurring Deposit',
    'Money Market Account',
  ];

  double get totalFunds => widget.group.totalBalance;

  @override
  void initState() {
    super.initState();
    // Extract account type and name from the combined string
    final nameParts = "";
    _selectedAccountType = nameParts[0];
    _nameController = TextEditingController(text: nameParts[1]);
    _balanceController = TextEditingController(
      text: "",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text('Are you sure you want to delete this account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context, {
                          'action': 'delete',
                          'account': "",
                        });
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width >= 600
          ? null
          : AppNavigation(
              selectedIndex: -1, // No tab selected in edit screen
              onDestinationSelected: (index) {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600)
            AppNavigation(
              selectedIndex: -1, // No tab selected in edit screen
              onDestinationSelected: (index) {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank: ${widget.group.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedAccountType,
                              decoration: const InputDecoration(
                                labelText: 'Account Type',
                                border: OutlineInputBorder(),
                              ),
                              items: _accountTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAccountType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Account Name/Number',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter account name or number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _balanceController,
                              decoration: const InputDecoration(
                                labelText: 'Balance',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter balance';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {

                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}