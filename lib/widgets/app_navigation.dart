import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_wallert/screens/bank_screen.dart';
import 'package:my_wallert/screens/dashboard_screen.dart';
import 'package:my_wallert/screens/fixed_deposit_screen.dart';
import 'package:my_wallert/screens/savings_screen.dart';
import 'package:my_wallert/screens/settings_screen.dart';
import 'package:my_wallert/screens/treasury_bill_screen.dart';
import 'package:my_wallert/screens/unity_trust_screen.dart';
import '../services/firebase_auth_service.dart';
import '../utils/preferences.dart';

class AppNavigation extends StatefulWidget {
  const AppNavigation({
    super.key,
  });

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation> {
  String _selectedRoute = '/dashboard';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context)?.settings.name;
    if (route != null && route != _selectedRoute) {
      setState(() {

        print("route : $route");
        _selectedRoute = route;
      });
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await Preferences.clearAuthToken();
        final authService = FirebaseAuthService();
        await authService.signOut();
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, '/signin');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;
        
        return Drawer(
          elevation: isDesktop ? 0 : 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              right: Radius.circular(0),
            ),
          ),
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                accountName: const Text('My Wallet'),
                accountEmail: Text(
                  currentUser?.email ?? 'Not signed in',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    currentUser?.email?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 24.0),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.dashboard, 
                  color: _selectedRoute == '/dashboard' ? Colors.blue : null),
                title: Text('Dashboard',
                  style: TextStyle(
                    color: _selectedRoute == '/dashboard' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/dashboard' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/dashboard' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/dashboard';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/dashboard'),
                      builder: (context) => DashboardScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.savings,
                  color: _selectedRoute == '/savings' ? Colors.blue : null),
                title: Text('Savings',
                  style: TextStyle(
                    color: _selectedRoute == '/savings' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/savings' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/savings' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/savings';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/savings'),
                      builder: (context) => const SavingsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lock,
                  color: _selectedRoute == '/fixed-deposits' ? Colors.blue : null),
                title: Text('Fixed Deposits',
                  style: TextStyle(
                    color: _selectedRoute == '/fixed-deposits' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/fixed-deposits' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/fixed-deposits' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/fixed-deposits';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/fixed-deposits'),
                      builder: (context) => const FixedDepositScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lock,
                  color: _selectedRoute == '/treasury-bill' ? Colors.blue : null),
                title: Text('Treasury Bill',
                  style: TextStyle(
                    color: _selectedRoute == '/treasury-bill' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/treasury-bill' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/treasury-bill' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/treasury-bill';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/treasury-bill'),
                      builder: (context) => const TreasuryBillScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.lock,
                  color: _selectedRoute == '/unity-trust' ? Colors.blue : null),
                title: Text('Unity Trust',
                  style: TextStyle(
                    color: _selectedRoute == '/unity-trust' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/unity-trust' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/unity-trust' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/unity-trust';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/unity-trust'),
                      builder: (context) => const UnityTrustScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.account_balance,
                  color: _selectedRoute == '/banks' ? Colors.blue : null),
                title: Text('Banks',
                  style: TextStyle(
                    color: _selectedRoute == '/banks' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/banks' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/banks' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/banks';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/banks'),
                      builder: (context) => const BankScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.settings,
                  color: _selectedRoute == '/settings' ? Colors.blue : null),
                title: Text('Settings',
                  style: TextStyle(
                    color: _selectedRoute == '/settings' ? Colors.blue : null,
                    fontWeight: _selectedRoute == '/settings' ? FontWeight.bold : null,
                  )),
                tileColor: _selectedRoute == '/settings' ? Colors.blue.withOpacity(0.1) : null,
                onTap: () {
                  setState(() {
                    _selectedRoute = '/settings';
                  });                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: '/settings'),
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    currentUser?.email?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(currentUser?.displayName ?? 'User'),
                subtitle: Text(currentUser?.email ?? 'Not signed in'),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (!isDesktop) {
                      Navigator.pop(context); // Close drawer first
                    }
                    
                    switch (value) {
                      case 'edit':
                        // TODO: Navigate to profile edit screen
                        break;
                      case 'logout':
                        await _handleSignOut(context);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Update Profile'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}