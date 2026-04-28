import 'package:flutter_test/flutter_test.dart';

import 'package:tap_counter/main.dart';

void main() {
  testWidgets('App renders timer setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TapCounterApp());
    expect(find.text('Set Timer'), findsOneWidget);
  });
}
