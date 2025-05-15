import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_wallert/screens/treasury_bill_screen.dart';
import 'package:my_wallert/services/get_it_service.dart';
import 'firebase_options.dart';
import 'screens/fixed_deposit_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/savings_screen.dart';
import 'screens/bank_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/unity_trust_screen.dart';
import 'widgets/app_navigation.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );

    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('Error initializing app: $e\n$stackTrace');
    // Show error screen instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error starting app: ${e.toString()}'),
        ),
      ),
    ));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const SavingsScreen();
      case 2:
        return const FixedDepositScreen();
      case 3:
        return const TreasuryBillScreen();
      case 4:
        return const UnityTrustScreen();
      case 5:
        return const BankScreen();
      case 6:
        return const SettingsScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Wallet',
      navigatorKey: _navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return Scaffold(
              drawer: MediaQuery.of(context).size.width >= 600
                  ? null
                  : AppNavigation(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
              body: Row(
                children: [
                  if (MediaQuery.of(context).size.width >= 600)
                    AppNavigation(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (int index) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        AppBar(
                          backgroundColor: Colors.white,
                          elevation: 4,
                          iconTheme: const IconThemeData(color: Colors.black87),
                          leading: MediaQuery.of(context).size.width < 600
                              ? Builder(
                                  builder: (context) => IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                  ),
                                )
                              : null,
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.notifications),
                              onPressed: () {
                                // TODO: Handle notification
                              },
                            ),
                          ],
                        ),
                        Expanded(
                          child: _getCurrentScreen(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return const SignInScreen();
        },
      ),
    );
  }
}
