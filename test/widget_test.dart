import 'package:flutter_test/flutter_test.dart';
import 'package:hiraya_app/main.dart';

void main() {
  testWidgets('Hiraya smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HirayaApp());
  });
}