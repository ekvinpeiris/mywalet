import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/account_group.dart';
import '../utils/currency_formatter.dart';
import '../screens/bank_details_screen.dart';
import '../controllers/bank_controller.dart';
import '../controllers/account_controller.dart';
import '../models/bank.dart';
import '../models/bank_account.dart';

class BankChart extends StatefulWidget {
  const BankChart({
    super.key,
  });

  @override
  State<BankChart> createState() => _BankChartState();
}

class _BankChartState extends State<BankChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int? _selectedBarIndex;
  late List<AccountGroup> _activeGroups;
  final BankController _bankController = BankController();
  final AccountController _accountController = AccountController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _activeGroups = [];
    _loadData();
  }

  Future<void> _loadData() async {
    final banks = await _bankController.getBanks().first;
    final List<AccountGroup> groups = [];
    
    for (Bank bank in banks) {
      if (bank.id != null) {
        final accounts = await _accountController.getAccounts(bank.id!).first;
        if (accounts.isNotEmpty) {
          double totalBalance = accounts.fold(0.0, (sum, acc) => sum + acc.balance);
          if (totalBalance > 0) {
            groups.add(AccountGroup(
              name: bank.bankName,
              accounts: accounts, // Pass the BankAccount list directly
              // totalBalance is calculated by the getter in AccountGroup
            ));
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {
        _activeGroups = groups;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBankColor(String bankName) {
    switch (bankName.toLowerCase()) {
      case 'bank of ceylon':
        return const Color(0xFF005BBB);
      case "people's bank":
        return const Color(0xFFE4002B);
      case 'commercial bank':
        return const Color(0xFF004488);
      case 'hatton national bank':
        return const Color(0xFFD6001C);
      case 'sampath bank':
        return const Color(0xFF008A4F);
      case 'seylan bank':
        return const Color(0xFFF58220);
      case 'nations trust bank':
        return const Color(0xFF662D91);
      case 'dfcc bank':
        return const Color(0xFF005AA9);
      case 'national savings bank':
        return const Color(0xFF0072BC);
      case 'pan asia banking corporation':
        return const Color(0xFF00808C);
      case 'amana bank':
        return const Color(0xFF008476);
      case 'union bank':
        return const Color(0xFFB90E0A);
      default:
        return Colors.blue;
    }
  }

  void _handleBarTap(int index) async {
    setState(() {
      _selectedBarIndex = index;
    });
    
    await _controller.forward();
    await _controller.reverse();
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BankDetailsScreen(
            group: _activeGroups[index],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_activeGroups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No banks with active accounts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    final maxBalance = _activeGroups.fold(
      0.0,
      (max, group) => group.totalBalance > max ? group.totalBalance : max,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bank Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxBalance * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final accountGroup = _activeGroups[groupIndex];
                      return BarTooltipItem(
                        '${accountGroup.name}\n${formatCurrency(accountGroup.totalBalance)}\nTap to view details',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is! FlPointerHoverEvent && response?.spot != null) {
                      final bankIndex = response!.spot!.touchedBarGroupIndex;
                      if (bankIndex >= 0 && bankIndex < _activeGroups.length) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BankDetailsScreen(
                              group: _activeGroups[bankIndex],
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _activeGroups.length) {
                          return const SizedBox.shrink();
                        }
                        
                        const style = TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        );
                        
                        // Get abbreviated bank name
                        final bankName = _activeGroups[value.toInt()].name;
                        final abbr = bankName.split(' ').map((word) => word[0]).join('');
                        
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 16,
                          child: Text(abbr, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 100,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          formatCurrencyCompact(value),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  checkToShowHorizontalLine: (value) => value % 100000 == 0,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                  checkToShowVerticalLine: (value) => false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                barGroups: _activeGroups.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.totalBalance,
                        color: _getBankColor(entry.value.name),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxBalance * 1.2,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
