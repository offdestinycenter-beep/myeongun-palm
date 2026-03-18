import 'package:flutter_test/flutter_test.dart';
import 'package:myeongun_palm/app.dart';

void main() {
  testWidgets('앱 시작 시 스플래시 화면 표시', (WidgetTester tester) async {
    await tester.pumpWidget(const MyeongunPalmApp());
    expect(find.text('명운관 손금'), findsOneWidget);
  });
}
