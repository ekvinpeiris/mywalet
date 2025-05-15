import 'package:flutter/material.dart';
import 'package:my_wallert/models/bank_account.dart';
import 'package:my_wallert/screens/base_screen.dart';
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
  final _dealerController = TextEditingController();
  final _isinController = TextEditingController();
  final _dealSlipNumberController = TextEditingController();
  final _faceValueController = TextEditingController();
  final _investmentValueController = TextEditingController();
  final _yieldPercentageController = TextEditingController();
  final _couponRateController = TextEditingController();
  final _couponValueController = TextEditingController();
  final _periodController = TextEditingController(); // Added period controller
  final _noteController = TextEditingController(); // For optional notes
  final _bankController = BankController();
  final _accountController = AccountController();
  Stream<List<Bank>>? _banksStream;
  DateTime? _startDate;
  DateTime? _maturityDate;
  DateTime? _nextCouponDate;
  bool _isLoading = false;
  int? _selectedDuration;
  String? _selectedInstrumentType;
  late String _selectedAccountType;

  final List<String> _instrumentTypes = ['bill', 'bond'];

  final List<int> _durationOptions = [1, 2, 3, 4, 6, 12, 24, 36, 48, 60];

  String? _selectedBank;
  String? _selectedTBillPeriod; // Added for Treasury Bill period selection
  bool _isAddingNewBank = false;

  final List<String> _accountTypes = [
    'Savings Account',
    'Fixed Deposit',
    'Treasury Bill',
    'Unity Trust',
    'Repo',
    'Money Market Account',
  ];

  String? _selectedInterestFrequency;
  final List<Map<String, String>> _interestFrequencyOptions = [
    {'value': 'maturity', 'label': 'On Maturity'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'annually', 'label': 'Annually'},
  ];

  InputDecoration _getInputDecoration(String label,
      {String? prefixText, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: TextStyle(color: Colors.grey.shade700),
      prefixText: prefixText,
      suffixText: suffixText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

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
    _interestRateController.dispose();
    _dealerController.dispose();
    _isinController.dispose();
    _dealSlipNumberController.dispose();
    _faceValueController.dispose();
    _investmentValueController.dispose();
    _yieldPercentageController.dispose();
    _couponRateController.dispose();    _couponValueController.dispose();
    _periodController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bank Selection Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Bank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<Bank>>(
                      stream: _banksStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        final banks = snapshot.data ?? [];

                        if (banks.isEmpty) {
                          return const Text(
                              'No banks available. Add a new bank.');
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
                          validator: (_) =>
                              _isAddingNewBank || _selectedBank != null
                                  ? null
                                  : 'Please select a bank or add a new one',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Account Details Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedAccountType,
                      decoration: _getInputDecoration('Account Type'),
                      items: _accountTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountType = value!;
                          if (value != 'Treasury Bill') {
                            _selectedInstrumentType = null;
                          }
                          // Clear name and balance if switching to Treasury Bill
                          if (value == 'Treasury Bill') {
                            _nameController.clear();
                            _balanceController.clear();
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                    if (_selectedAccountType != 'Treasury Bill') ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: _getInputDecoration('Account Name/Number'),
                        validator: (value) {
                          if (_selectedAccountType != 'Treasury Bill' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter account name or number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _balanceController,
                        decoration:
                            _getInputDecoration('Balance', prefixText: 'Rs '),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedAccountType != 'Treasury Bill' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter balance';
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_selectedAccountType == 'Fixed Deposit') ...[
                      DropdownButtonFormField<int>(
                        value: _selectedDuration,
                        decoration: _getInputDecoration('Duration'),
                        items: _durationOptions.map((months) {
                          return DropdownMenuItem(
                            value: months,
                            child: Text(
                                '${months} ${months == 1 ? 'month' : 'months'}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDuration = value;
                            // Update maturity date based on selected duration
                            if (_startDate != null && value != null) {
                              _maturityDate = DateTime(_startDate!.year,
                                  _startDate!.month + value, _startDate!.day);
                            }
                          });
                        },
                        validator: (value) {
                          if (_selectedAccountType == 'Fixed Deposit' &&
                              value == null) {
                            return 'Please select duration';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration: _getInputDecoration('Start Date').copyWith(
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
                                        selectedDate.day);
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
                          if (_selectedAccountType == 'Fixed Deposit' &&
                              _startDate == null) {
                            return 'Please select start date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        readOnly: true,
                        decoration:
                            _getInputDecoration('Maturity Date').copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              if (_startDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please select start date first'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: _maturityDate ??
                                    _startDate!.add(const Duration(days: 365)),
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
                          if (_selectedAccountType == 'Fixed Deposit' &&
                              _maturityDate == null) {
                            return 'Please select maturity date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _interestRateController,
                        decoration: _getInputDecoration('Interest Rate (%)'),
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
                      DropdownButtonFormField<String>(
                        value: _selectedInterestFrequency,
                        decoration:
                            _getInputDecoration('Interest Payout Frequency'),
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
                          if (_selectedAccountType == 'Fixed Deposit' &&
                              value == null) {
                            return 'Please select interest payout frequency';
                          }
                          return null;
                        },
                      ),
                    ],
                    if (_selectedAccountType == 'Treasury Bill') ...[
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedInstrumentType,
                        decoration: _getInputDecoration('Instrument Type'),
                        items: _instrumentTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedInstrumentType = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedAccountType == 'Treasury Bill' &&
                              value == null) {
                            return 'Please select instrument type';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _isinController,
                        decoration: _getInputDecoration('ISIN'),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _dealSlipNumberController,
                        decoration: _getInputDecoration('Deal Slip Number'),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        readOnly: true,
                        decoration: _getInputDecoration('Start Date').copyWith(
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
                                  // Update maturity date based on period if selected
                                  if (_selectedTBillPeriod != null) {
                                    _maturityDate = selectedDate.add(Duration(
                                        days:
                                            int.parse(_selectedTBillPeriod!)));
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
                          if (_selectedAccountType == 'Treasury Bill' &&
                              _startDate == null) {
                            return 'Please select start date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _periodController,
                        decoration: _getInputDecoration('Period in Days'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            _selectedTBillPeriod = value;
                            // Auto-calculate maturity date based on period and start date
                            if (value.isNotEmpty && _startDate != null) {
                              try {
                                final days = int.parse(value);
                                _maturityDate =
                                    _startDate!.add(Duration(days: days));
                              } catch (e) {
                                // Invalid number, don't update maturity date
                              }
                            }
                            // Calculate face value when period changes
                          });
                        },
                        validator: (value) {
                          if (_selectedAccountType == 'Treasury Bill' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter period in days';
                          }
                          if (value != null &&
                              value.isNotEmpty &&
                              int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        readOnly: true,
                        decoration: _getInputDecoration(
                          'Maturity Date',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final selectedDate = await showDatePicker(
                                context: context,
                                initialDate: _maturityDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.blue.shade400,
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _investmentValueController,
                        decoration: _getInputDecoration('Investment Value',
                            prefixText: 'Rs '),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {},
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _yieldPercentageController,
                        decoration: _getInputDecoration('Yield Percentage',
                            suffixText: '%'),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {},
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_selectedInstrumentType == 'bond') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _couponRateController,
                          decoration: _getInputDecoration('Coupon Rate',
                              suffixText: '%'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {},
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          readOnly: true,
                          decoration:
                              _getInputDecoration('Next Coupon Date').copyWith(
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final selectedDate = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      _nextCouponDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (selectedDate != null) {
                                  setState(() {
                                    _nextCouponDate = selectedDate;
                                  });
                                }
                              },
                            ),
                          ),
                          controller: TextEditingController(
                            text: _nextCouponDate != null
                                ? '${_nextCouponDate!.day}/${_nextCouponDate!.month}/${_nextCouponDate!.year}'
                                : '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _couponValueController,
                          decoration: _getInputDecoration('Coupon Value',
                              prefixText: 'Rs '),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {},
                          validator: (value) {
                            if (value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _faceValueController,
                        decoration:
                            _getInputDecoration('Face Value', prefixText: 'Rs ')
                                .copyWith(
                          enabled: true,
                          fillColor: Colors.grey[100],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    const SizedBox(height: 16),
                    // Note field
                    TextFormField(
                      controller: _noteController,
                      decoration: _getInputDecoration('Note',).copyWith(
                        helperText: 'Optional: Add any additional notes or comments',
                      ),
                      maxLines: 3,  // Allow multiple lines for notes
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              if (_selectedBank != null) {
                                final account = BankAccount(
                                  accountType: _selectedAccountType,
                                  accountNumber: _selectedAccountType ==
                                          'Treasury Bill'
                                      ? '${_isinController.text}-${_dealSlipNumberController.text}'
                                      : _nameController.text,
                                  balance: _selectedAccountType ==
                                          'Treasury Bill'
                                      ? double.parse(_faceValueController.text)
                                      : double.parse(_balanceController.text),
                                  startDate: (_selectedAccountType ==
                                              'Fixed Deposit' ||
                                          _selectedAccountType ==
                                              'Treasury Bill')
                                      ? _startDate
                                      : null,
                                  maturityDate: (_selectedAccountType ==
                                              'Fixed Deposit' ||
                                          _selectedAccountType ==
                                              'Treasury Bill')
                                      ? _maturityDate
                                      : null,
                                  interestRate:
                                      _selectedAccountType == 'Fixed Deposit'
                                          ? double.parse(
                                              _interestRateController.text)
                                          : null,
                                  durationInMonths:
                                      _selectedAccountType == 'Fixed Deposit'
                                          ? _selectedDuration
                                          : null,
                                  interestPayoutFrequency:
                                      _selectedAccountType == 'Fixed Deposit'
                                          ? _selectedInterestFrequency
                                          : null,
                                  // Treasury Bill specific fields
                                  instrumentType:
                                      _selectedAccountType == 'Treasury Bill'
                                          ? _selectedInstrumentType
                                          : null,
                                  period:
                                      _selectedAccountType == 'Treasury Bill'
                                          ? int.parse(_selectedTBillPeriod!)
                                          : null,
                                  isin: _selectedAccountType == 'Treasury Bill'
                                      ? _isinController.text
                                      : null,
                                  dealSlipNumber:
                                      _selectedAccountType == 'Treasury Bill'
                                          ? _dealSlipNumberController.text
                                          : null,
                                  faceValue: _selectedAccountType ==
                                              'Treasury Bill' &&
                                          _faceValueController.text.isNotEmpty
                                      ? double.parse(_faceValueController.text)
                                      : null,
                                  investmentValue:
                                      _selectedAccountType == 'Treasury Bill' &&
                                              _investmentValueController
                                                  .text.isNotEmpty
                                          ? double.parse(
                                              _investmentValueController.text)
                                          : null,
                                  yieldPercentage:
                                      _selectedAccountType == 'Treasury Bill' &&
                                              _yieldPercentageController
                                                  .text.isNotEmpty
                                          ? double.parse(
                                              _yieldPercentageController.text)
                                          : null,                                  // Bond specific fields
                                  couponRate: _selectedInstrumentType == 'bond' &&
                                          _couponRateController.text.isNotEmpty
                                      ? double.parse(_couponRateController.text)
                                      : null,
                                  nextCouponDate:
                                      _selectedAccountType == 'Treasury Bill' &&
                                              _selectedInstrumentType == 'bond'
                                          ? _nextCouponDate
                                          : null,
                                  couponValue: _selectedAccountType ==
                                              'Treasury Bill' &&
                                          _selectedInstrumentType == 'bond' &&
                                          _couponValueController.text.isNotEmpty                                      ? double.parse(
                                          _couponValueController.text)
                                      : null,
                                  note: _noteController.text.isEmpty ? null : _noteController.text,
                                  bankId: _selectedBank,
                                );

                                await _accountController.addAccount(
                                    _selectedBank!, account);

                                if (mounted) {
                                  Navigator.pop(context, {
                                    'success': true,
                                    'account': account,
                                    'bankId': _selectedBank,
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Account created successfully'),
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
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
