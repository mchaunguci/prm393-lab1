import 'package:flutter_test/flutter_test.dart';
import 'package:shopee_app/main.dart';

void main() {
  testWidgets('App should build', (WidgetTester tester) async {
    await tester.pumpWidget(const ShopeeApp());
    expect(find.text('Shopee Product Manager'), findsOneWidget);
  });
}
