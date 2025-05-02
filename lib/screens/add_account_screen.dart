import 'package:flutter/material.dart';
import 'package:my_wallert/models/bank_account.dart';
import '../widgets/app_navigation.dart';
import '../controllers/bank_controller.dart';
import '../controllers/account_controller.dart';
import '../models/bank.dart';

class AddAccountScreen extends StatefulWidget {

  final int selectedAccountType;
  const AddAccountScreen({
    super.key,
    required this.selectedAccountType,
  });

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _newBankController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _bankController = BankController();
  final _accountController = AccountController();
  Stream<List<Bank>>? _banksStream;
  DateTime? _startDate;
  DateTime? _maturityDate;
  bool _isLoading = false;
  int? _selectedDuration;

  final List<int> _durationOptions = [1, 2, 3, 4, 6, 12, 24, 36, 48, 60];

  String? _selectedBank;
  bool _isAddingNewBank = false;

  late String _selectedAccountType;
  final List<String> _accountTypes = [
    'Savings Account',
    'Fixed Deposit',
    'Checking Account',
    'Current Account',
    'Recurring Deposit',
    'Money Market Account',
  ];

  String? _selectedInterestFrequency;
  final List<Map<String, String>> _interestFrequencyOptions = [
    {'value': 'on_maturity', 'label': 'On Maturity'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'annually', 'label': 'Annually'},
  ];

  @override
  void initState() {
    super.initState();
    _banksStream = _bankController.getBanks();

    _selectedAccountType = _accountTypes[widget.selectedAccountType];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _newBankController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (MediaQuery.of(context).size.width >= 600)
          AppNavigation(
            selectedIndex: -1, // No tab selected in add screen
            onDestinationSelected: (index) {
              Navigator.of(context).pushReplacementNamed('/home');
            },
          ),
        Expanded(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Add Account'),
              elevation: 2,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black, // For text and icons
            ),
            drawer: MediaQuery.of(context).size.width >= 600
                ? null
                : AppNavigation(
                    selectedIndex: -1,
                    onDestinationSelected: (index) {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                  ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bank Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Bank',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<List<Bank>>(
                              stream: _banksStream,
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }

                                final banks = snapshot.data ?? [];

                                if (banks.isEmpty) {
                                  return const Text('No banks available. Add a new bank.');
                                }

                                return DropdownButtonFormField<String>(
                                  value: _selectedBank,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Select a bank',
                                  ),
                                  items: banks.map((bank) {
                                    return DropdownMenuItem(
                                      value: bank.id,
                                      child: Text(bank.bankName),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedBank = value;
                                    });
                                  },
                                  validator: (_) => _isAddingNewBank || _selectedBank != null
                                      ? null
                                      : 'Please select a bank or add a new one',
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Account Type Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Details',
                              style: TextStyle(
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
                                prefixText: 'Rs ',
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
                            const SizedBox(height: 16),
                            if (_selectedAccountType == 'Fixed Deposit') ...[
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () async {
                                      final selectedDate = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate ?? DateTime.now(),
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectedDate != null) {
                                        setState(() {
                                          _startDate = selectedDate;
                                          // Update maturity date when start date changes
                                          if (_selectedDuration != null) {
                                            _maturityDate = DateTime(
                                              selectedDate.year, 
                                              selectedDate.month + _selectedDuration!, 
                                              selectedDate.day
                                            );
                                          }
                                        });
                                      }
                                    },
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: _startDate != null
                                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                      : '',
                                ),
                                validator: (value) {
                                  if (_selectedAccountType == 'Fixed Deposit' && _startDate == null) {
                                    return 'Please select start date';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Maturity Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () async {
                                      if (_startDate == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Please select start date first'),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        return;
                                      }
                                      final selectedDate = await showDatePicker(
                                        context: context,
                                        initialDate: _maturityDate ?? _startDate!.add(const Duration(days: 365)),
                                        firstDate: _startDate!,
                                        lastDate: DateTime(2100),
                                      );
                                      if (selectedDate != null) {
                                        setState(() {
                                          _maturityDate = selectedDate;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                controller: TextEditingController(
                                  text: _maturityDate != null
                                      ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                                      : '',
                                ),
                                validator: (value) {
                                  if (_selectedAccountType == 'Fixed Deposit' && _maturityDate == null) {
                                    return 'Please select maturity date';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _interestRateController,
                                decoration: const InputDecoration(
                                  labelText: 'Interest Rate (%)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter interest rate';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<int>(
                                value: _selectedDuration,
                                decoration: const InputDecoration(
                                  labelText: 'Duration',
                                  border: OutlineInputBorder(),
                                ),
                                items: _durationOptions.map((months) {
                                  return DropdownMenuItem(
                                    value: months,
                                    child: Text('${months} ${months == 1 ? 'month' : 'months'}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDuration = value;
                                    // Update maturity date based on selected duration
                                    if (_startDate != null && value != null) {
                                      _maturityDate = DateTime(_startDate!.year, _startDate!.month + value, _startDate!.day);
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (_selectedAccountType == 'Fixed Deposit' && value == null) {
                                    return 'Please select duration';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedInterestFrequency,
                                decoration: const InputDecoration(
                                  labelText: 'Interest Payout Frequency',
                                  border: OutlineInputBorder(),
                                ),
                                items: _interestFrequencyOptions.map((option) {
                                  return DropdownMenuItem(
                                    value: option['value'],
                                    child: Text(option['label']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedInterestFrequency = value;
                                  });
                                },
                                validator: (value) {
                                  if (_selectedAccountType == 'Fixed Deposit' && value == null) {
                                    return 'Please select interest payout frequency';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 250,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                if (_selectedBank != null) {
                                  final account = BankAccount(
                                    accountType: _selectedAccountType,
                                    accountNumber: _nameController.text,
                                    balance: double.parse(_balanceController.text),
                                    startDate: _selectedAccountType == 'Fixed Deposit' ? _startDate : null,
                                    maturityDate: _selectedAccountType == 'Fixed Deposit' ? _maturityDate : null,
                                    interestRate: _selectedAccountType == 'Fixed Deposit' ?
                                        double.parse(_interestRateController.text) : null,
                                    durationInMonths: _selectedAccountType == 'Fixed Deposit' ?
                                        _selectedDuration : null,
                                    interestPayoutFrequency: _selectedAccountType == 'Fixed Deposit' ?
                                        _selectedInterestFrequency : null,
                                    bankId: _selectedBank,
                                  );

                                  await _accountController.addAccount(_selectedBank!, account);

                                  if (mounted) {
                                    Navigator.pop(context, {
                                      'success': true,
                                      'account': account,
                                      'bankId': _selectedBank,
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Account created successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  throw Exception('Bank not found');
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error creating account: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Save Account'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}