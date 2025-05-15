import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../utils/preferences.dart';

class AppNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AppNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

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
          shape: RoundedRectangleBorder(
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
                selected: selectedIndex == 0,
                leading: const Icon(Icons.dashboard),
                title: const Text('Dashboard'),
                onTap: () {
                  onDestinationSelected(0);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                selected: selectedIndex == 1,
                leading: const Icon(Icons.savings),
                title: const Text('Savings'),
                onTap: () {
                  onDestinationSelected(1);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                selected: selectedIndex == 2,
                leading: const Icon(Icons.lock),
                title: const Text('Fixed Deposits'),
                onTap: () {
                  onDestinationSelected(2);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                selected: selectedIndex == 3,
                leading: const Icon(Icons.lock),
                title: const Text('Treasury Bill'),
                onTap: () {
                  onDestinationSelected(3);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                selected: selectedIndex == 4,
                leading: const Icon(Icons.lock),
                title: const Text('Unity Trust'),
                onTap: () {
                  onDestinationSelected(4);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                selected: selectedIndex == 5,
                leading: const Icon(Icons.account_balance),
                title: const Text('Banks'),
                onTap: () {
                  onDestinationSelected(5);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
                },
              ),
              ListTile(
                selected: selectedIndex == 6,
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  onDestinationSelected(6);
                  if (!isDesktop) {
                    Navigator.pop(context);
                  }
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