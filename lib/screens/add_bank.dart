import 'package:flutter/material.dart';
import 'package:my_wallert/widgets/app_navigation.dart';
import '../controllers/bank_controller.dart';

class AddBank extends StatefulWidget {
  const AddBank({super.key});

  @override
  State<AddBank> createState() => _AddBankState();
}

class _AddBankState extends State<AddBank> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bankController = BankController();
  bool _isLoading = false;

  Future<void> _saveBank() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _bankController.createBank(_nameController.text.trim());
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          // Remove 'Exception: ' from the error message if it exists
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(10);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                textColor: Colors.white,
              ),
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
              title: const Text('Add New Bank'),
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
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                      ),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'New Bank Name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter bank name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  width: 250,
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _saveBank,
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
                                            ),
                                          )
                                        : const Text('Save Bank'),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
