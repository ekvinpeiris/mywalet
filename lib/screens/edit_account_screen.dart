import 'package:flutter/material.dart';
import 'package:my_wallert/screens/base_screen.dart';
import '../models/bank_account.dart';
import '../utils/currency_formatter.dart';
import '../controllers/account_controller.dart';
import '../controllers/bank_controller.dart';

class EditAccountScreen extends StatefulWidget {
  final String bankId;
  final BankAccount account;

  const EditAccountScreen({
    super.key,
    required this.bankId,
    required this.account,
  });

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  late final TextEditingController _isinController;
  late final TextEditingController _dealSlipNumberController;
  late final TextEditingController _faceValueController;
  late final TextEditingController _investmentValueController;
  late final TextEditingController _yieldPercentageController;
  late final TextEditingController _periodController;
  late final TextEditingController _couponRateController;
  late final TextEditingController _couponValueController;
  late final TextEditingController _noteController;
  late final TextEditingController _interestRateController;  // Added for FD interest rate
  
  late String _selectedAccountType;
  late String? _selectedInstrumentType;
  late String? _selectedTBillPeriod;
  late int? _selectedDuration;  // Added for FD duration
  late String? _selectedInterestFrequency;  // Added for FD interest frequency
  DateTime? _startDate;
  DateTime? _maturityDate;
  DateTime? _nextCouponDate;
  bool _isLoading = false;
  final AccountController _accountController = AccountController();

  final List<String> _accountTypes = [
    'Savings Account',
    'Fixed Deposit',
    'Treasury Bill',
    'Checking Account',
    'Current Account',
    'Recurring Deposit',
    'Money Market Account',
  ];

  final List<String> _instrumentTypes = ['bill', 'bond'];

  final List<int> _durationOptions = [1, 2, 3, 4, 6, 12, 24, 36, 48, 60];  // Added for FD durations

  final List<Map<String, String>> _interestFrequencyOptions = [  // Added for FD interest frequencies
    {'value': 'maturity', 'label': 'On Maturity'},
    {'value': 'monthly', 'label': 'Monthly'},
    {'value': 'annually', 'label': 'Annually'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedAccountType = widget.account.accountType;
    _selectedInstrumentType = widget.account.instrumentType;
    _selectedTBillPeriod = widget.account.period?.toString();
    _selectedDuration = widget.account.durationInMonths;  // Added for FD
    _selectedInterestFrequency = widget.account.interestPayoutFrequency;  // Added for FD
    _startDate = widget.account.startDate;
    _maturityDate = widget.account.maturityDate;
    _nextCouponDate = widget.account.nextCouponDate;
    
    _nameController = TextEditingController(text: widget.account.accountNumber);
    _balanceController = TextEditingController(
      text: widget.account.balance.toString(),
    );
    _isinController = TextEditingController(
      text: widget.account.isin ?? '',
    );
    _dealSlipNumberController = TextEditingController(
      text: widget.account.dealSlipNumber ?? '',
    );
    _faceValueController = TextEditingController(
      text: widget.account.faceValue?.toString() ?? '',
    );
    _investmentValueController = TextEditingController(
      text: widget.account.investmentValue?.toString() ?? '',
    );
    _yieldPercentageController = TextEditingController(
      text: widget.account.yieldPercentage?.toString() ?? '',
    );
    _periodController = TextEditingController(
      text: widget.account.period?.toString() ?? '',
    );
    _couponRateController = TextEditingController(
      text: widget.account.couponRate?.toString() ?? '',
    );
    _couponValueController = TextEditingController(
      text: widget.account.couponValue?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.account.note ?? '',
    );
    _interestRateController = TextEditingController(  // Added for FD
      text: widget.account.interestRate?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _noteController.dispose();
    _isinController.dispose();
    _dealSlipNumberController.dispose();
    _faceValueController.dispose();
    _investmentValueController.dispose();
    _yieldPercentageController.dispose();
    _periodController.dispose();
    _couponRateController.dispose();
    _couponValueController.dispose();
    _interestRateController.dispose();  // Added for FD
    super.dispose();
  }

  InputDecoration _getInputDecoration(String label, {String? prefixText, String? suffixText, String? helperText}) {
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
      helperText: helperText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: Container(
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
                      StreamBuilder<String>(
                        stream: BankController().getBankName(widget.bankId),
                        builder: (context, snapshot) {
                          return Text(
                            'Bank: ${snapshot.data ?? 'Loading...'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedAccountType,                        decoration: _getInputDecoration('Account Type'),
                        items: _accountTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: null,  // Not allowing account type changes
                      ),

                      if (_selectedAccountType == 'Treasury Bill') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedInstrumentType,
                          decoration: _getInputDecoration(
                            'Instrument Type *',
                            helperText: 'Required: Select bill or bond type',
                          ),
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
                            if (value == null || value.isEmpty) {
                              return 'Please select an instrument type';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _isinController,
                          decoration: _getInputDecoration(
                            'ISIN *',
                            helperText: 'Required: Enter the International Securities Identification Number',
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter ISIN';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dealSlipNumberController,
                          decoration: _getInputDecoration(
                            'Deal Slip Number *',
                            helperText: 'Required: Enter the deal slip/reference number',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter deal slip number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                : '',
                          ),
                          decoration: _getInputDecoration(
                            'Start Date *',
                            helperText: 'Required: Select the issue date',
                            suffixText: null,
                          ).copyWith(
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
                                    if (_selectedTBillPeriod != null) {
                                      _maturityDate = selectedDate.add(
                                        Duration(days: int.parse(_selectedTBillPeriod!)),
                                      );
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                          validator: (value) {
                            if (_startDate == null) {
                              return 'Please select start date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _periodController,
                          decoration: _getInputDecoration(
                            'Period in Days *',
                            helperText: 'Required: Enter the period (e.g., 91, 182, or 364 days)',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _selectedTBillPeriod = value;
                              if (value.isNotEmpty && _startDate != null) {
                                try {
                                  final days = int.parse(value);
                                  _maturityDate = _startDate!.add(Duration(days: days));
                                } catch (e) {
                                  // Invalid number, don't update maturity date
                                }
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter period in days';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _maturityDate != null
                                ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                                : '',
                          ),
                          decoration: _getInputDecoration(
                            'Maturity Date',
                            helperText: 'Auto-calculated based on start date and period',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _faceValueController,
                          decoration: _getInputDecoration(
                            'Face Value *',
                            prefixText: 'Rs ',
                            helperText: 'Required: Enter the face value/par value',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _balanceController.text = value;  // Update balance to match face value
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter face value';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _investmentValueController,
                          decoration: _getInputDecoration(
                            'Investment Value *',
                            prefixText: 'Rs ',
                            helperText: 'Required: Enter the actual investment amount',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter investment value';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _yieldPercentageController,
                          decoration: _getInputDecoration(
                            'Yield Percentage *',
                            suffixText: '%',
                            helperText: 'Required: Enter the yield percentage',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter yield percentage';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        // Bond-specific fields
                        if (_selectedInstrumentType == 'bond') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _couponRateController,
                            decoration: _getInputDecoration(
                              'Coupon Rate *',
                              suffixText: '%',
                              helperText: 'Required for bonds: Enter the coupon rate',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_selectedInstrumentType == 'bond' && (value == null || value.isEmpty)) {
                                return 'Please enter coupon rate';
                              }
                              if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _nextCouponDate != null
                                  ? '${_nextCouponDate!.day}/${_nextCouponDate!.month}/${_nextCouponDate!.year}'
                                  : '',
                            ),
                            decoration: _getInputDecoration(
                              'Next Coupon Date *',
                              helperText: 'Required for bonds: Select next coupon payment date',
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: _nextCouponDate ?? DateTime.now(),
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
                            validator: (value) {
                              if (_selectedInstrumentType == 'bond' && _nextCouponDate == null) {
                                return 'Please select next coupon date';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _couponValueController,
                            decoration: _getInputDecoration(
                              'Coupon Value *',
                              prefixText: 'Rs ',
                              helperText: 'Required for bonds: Enter the coupon payment amount',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_selectedInstrumentType == 'bond' && (value == null || value.isEmpty)) {
                                return 'Please enter coupon value';
                              }
                              if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ] else if (_selectedAccountType == 'Fixed Deposit') ...[
                        const SizedBox(height: 16),
                        // Start Date
                        TextFormField(
                          readOnly: true,
                          decoration: _getInputDecoration(
                            'Start Date *',
                            helperText: 'Required: Select the start date of the deposit',
                          ).copyWith(
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
                                    // Update maturity date based on selected duration
                                    if (_selectedDuration != null) {
                                      _maturityDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month + _selectedDuration!,
                                        selectedDate.day,
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
                            if (_startDate == null) {
                              return 'Please select start date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Maturity Date (Read-only)
                        TextFormField(
                          readOnly: true,
                          decoration: _getInputDecoration(
                            'Maturity Date',
                            helperText: 'Auto-calculated based on start date and duration',
                          ),
                          controller: TextEditingController(
                            text: _maturityDate != null
                                ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                                : '',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Interest Rate
                        TextFormField(
                          controller: _interestRateController,
                          decoration: _getInputDecoration(
                            'Interest Rate *',
                            suffixText: '%',
                            helperText: 'Required: Enter the interest rate percentage',
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
                        // Duration in Months
                        DropdownButtonFormField<int>(
                          value: _selectedDuration,
                          decoration: _getInputDecoration(
                            'Duration *',
                            helperText: 'Required: Select the duration of the deposit',
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
                                _maturityDate = DateTime(
                                  _startDate!.year,
                                  _startDate!.month + value,
                                  _startDate!.day,
                                );
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select duration';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Interest Payout Frequency
                        DropdownButtonFormField<String>(
                          value: _selectedInterestFrequency,
                          decoration: _getInputDecoration(
                            'Interest Payout Frequency *',
                            helperText: 'Required: Select how often the interest is paid out',
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
                            if (value == null) {
                              return 'Please select interest payout frequency';
                            }
                            return null;
                          },
                        ),
                        // Keep existing fields for name and balance
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: _getInputDecoration('Account Name/Number'),
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
                          decoration: _getInputDecoration(
                            'Balance',
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

                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _noteController,
                        decoration: _getInputDecoration(
                          'Note',
                          helperText: 'Optional: Add any additional notes or comments',
                        ),
                        maxLines: 3,  // Allow multiple lines for notes
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                              // Create updated account object preserving existing fields
                              final updatedAccount = BankAccount(
                                id: widget.account.id,
                                accountType: _selectedAccountType,
                                accountNumber: _selectedAccountType == 'Treasury Bill'
                                    ? '${_isinController.text}-${_dealSlipNumberController.text}'
                                    : _nameController.text,
                                balance: _selectedAccountType == 'Treasury Bill'
                                    ? double.parse(_faceValueController.text)
                                    : double.parse(_balanceController.text),
                                bankId: widget.bankId,
                                userId: widget.account.userId,
                                startDate: _startDate,
                                maturityDate: _maturityDate,
                                // Fixed Deposit specific fields
                                interestRate: _selectedAccountType == 'Fixed Deposit'
                                    ? double.parse(_interestRateController.text)
                                    : null,
                                durationInMonths: _selectedAccountType == 'Fixed Deposit'
                                    ? _selectedDuration
                                    : null,
                                interestPayoutFrequency: _selectedAccountType == 'Fixed Deposit'
                                    ? _selectedInterestFrequency
                                    : null,
                                note: _noteController.text.isEmpty ? null : _noteController.text,
                                // Treasury Bill specific fields
                                instrumentType: _selectedAccountType == 'Treasury Bill'
                                    ? _selectedInstrumentType
                                    : null,
                                period: _selectedAccountType == 'Treasury Bill'
                                    ? int.tryParse(_periodController.text)
                                    : null,
                                isin: _selectedAccountType == 'Treasury Bill'
                                    ? _isinController.text
                                    : null,
                                dealSlipNumber: _selectedAccountType == 'Treasury Bill'
                                    ? _dealSlipNumberController.text
                                    : null,
                                faceValue: _selectedAccountType == 'Treasury Bill' &&
                                        _faceValueController.text.isNotEmpty
                                    ? double.parse(_faceValueController.text)
                                    : null,
                                investmentValue: _selectedAccountType == 'Treasury Bill' &&
                                        _investmentValueController.text.isNotEmpty
                                    ? double.parse(_investmentValueController.text)
                                    : null,
                                yieldPercentage: _selectedAccountType == 'Treasury Bill' &&
                                        _yieldPercentageController.text.isNotEmpty
                                    ? double.parse(_yieldPercentageController.text)
                                    : null,
                                // Bond specific fields
                                couponRate: _selectedAccountType == 'Treasury Bill' &&
                                        _selectedInstrumentType == 'bond' &&
                                        _couponRateController.text.isNotEmpty
                                    ? double.parse(_couponRateController.text)
                                    : null,
                                nextCouponDate: _selectedAccountType == 'Treasury Bill' &&
                                        _selectedInstrumentType == 'bond'
                                    ? _nextCouponDate
                                    : null,
                                couponValue: _selectedAccountType == 'Treasury Bill' &&
                                        _selectedInstrumentType == 'bond' &&
                                        _couponValueController.text.isNotEmpty
                                    ? double.parse(_couponValueController.text)
                                    : null,
                              );

                              // Update the account
                              await _accountController.updateAccount(
                                widget.bankId,
                                widget.account.id!,
                                updatedAccount,
                              );

                              if (mounted) {
                                Navigator.pop(context, {
                                  'success': true,
                                  'account': updatedAccount,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Account updated successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error updating account: $e'),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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
                      : const Text(
                          'Save Changes',
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