import 'package:flutter/material.dart';
import '../models/bank_account.dart'; // Changed import
import '../models/account_group.dart';
import '../utils/currency_formatter.dart';
import '../widgets/app_navigation.dart';

class BankDetailsScreen extends StatelessWidget {
  final AccountGroup group;
  final int selectedIndex;

  const BankDetailsScreen({
    super.key,
    required this.group,
    this.selectedIndex = 3, // Default to Banks tab
  });

  @override
  Widget build(BuildContext context) {
    // Updated filtering logic to use accountType
    final savingsAccounts = group.accounts
        .where((account) => account.accountType == 'Savings Account')
        .toList();
    final fixedDeposits = group.accounts
        .where((account) => account.accountType == 'Fixed Deposit')
        .toList();
    final currentAccounts = group.accounts
        .where((account) => account.accountType == 'Current Account')
        .toList();

    final totalFunds = group.accounts.fold(
      0.0,
      (sum, account) => sum + account.balance,
    );

    return Scaffold(
      drawer: MediaQuery.of(context).size.width >= 600
          ? null
          : AppNavigation(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (index != selectedIndex) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600)
            AppNavigation(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                if (index != selectedIndex) {
                  Navigator.of(context).pushReplacementNamed('/home');
                }
              },
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bank Summary Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.account_balance,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                Text(
                                  formatCurrency(group.totalBalance),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'Total Accounts',
                                  group.accounts.length.toString(),
                                  Icons.account_balance_wallet,
                                ),
                                _buildStatItem(
                                  'Savings',
                                  savingsAccounts.length.toString(),
                                  Icons.savings,
                                ),
                                _buildStatItem(
                                  'Fixed Deposits',
                                  fixedDeposits.length.toString(),
                                  Icons.lock,
                                ),
                                _buildStatItem(
                                  'Current',
                                  currentAccounts.length.toString(),
                                  Icons.account_balance,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Savings Accounts Section
                    if (savingsAccounts.isNotEmpty) ...[
                      _buildSectionHeader('Savings Accounts', Icons.savings, Colors.green),
                      const SizedBox(height: 16),
                      ...savingsAccounts.map((account) => _buildAccountCard(
                            account,
                            Icons.savings,
                            Colors.green,
                          )),
                      const SizedBox(height: 24),
                    ],
                    // Fixed Deposits Section
                    if (fixedDeposits.isNotEmpty) ...[
                      _buildSectionHeader('Fixed Deposits', Icons.lock, Colors.orange),
                      const SizedBox(height: 16),
                      ...fixedDeposits.map((account) => _buildAccountCard(
                            account,
                            Icons.lock,
                            Colors.orange,
                          )),
                      const SizedBox(height: 24),
                    ],
                    // Current Accounts Section
                    if (currentAccounts.isNotEmpty) ...[
                      _buildSectionHeader('Current Accounts', Icons.account_balance, Colors.purple),
                      const SizedBox(height: 16),
                      ...currentAccounts.map((account) => _buildAccountCard(
                            account,
                            Icons.account_balance,
                            Colors.purple,
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Updated method signature and title display
  Widget _buildAccountCard(BankAccount account, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(account.accountNumber), // Display account number
        subtitle: Text(
          formatCurrency(account.balance),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implement edit functionality
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                // TODO: Implement delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}
