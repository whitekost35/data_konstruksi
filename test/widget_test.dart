import 'package:flutter_test/flutter_test.dart';
import 'package:data_konstruksi/main.dart';

void main() {
  testWidgets('App starts without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const DataKonstruksiApp());
  });
}
