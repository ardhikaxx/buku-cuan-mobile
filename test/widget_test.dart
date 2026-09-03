import 'package:flutter_test/flutter_test.dart';
import 'package:buku_cuan_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BukuCuanApp());
    await tester.pumpAndSettle();
    expect(find.text('Aktifkan Buku Cuan'), findsOneWidget);
  });
}
