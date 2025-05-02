import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_wallet/main.dart';

void main() {
  testWidgets('App should render with correct title and text', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is correct
    expect(find.text('My Accounts'), findsOneWidget);
    
    // Verify that the "No accounts added yet" text is present
    expect(find.text('No accounts added yet.'), findsOneWidget);
    
    // Verify that the FloatingActionButton is present
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
} 