import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dailytask/screens/pin_lock_screen.dart';

void main() {
  testWidgets('PinLockScreen renders keypad and prompt', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PinLockScreen(mode: PinMode.setup),
      ),
    );

    // Verify setup title and digits are present
    expect(find.text('Create a 4-Digit PIN'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
