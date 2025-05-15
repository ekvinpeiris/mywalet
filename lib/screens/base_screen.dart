import 'package:flutter/material.dart';
import 'package:my_wallert/widgets/app_navigation.dart';

class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key, required this.child});
  final Widget child;

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MediaQuery.of(context).size.width >= 600
          ? null
          :  AppNavigation(
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 600)
            const AppNavigation(
            ),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.white,
                  elevation: 2,
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
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),

    );
  }
}
