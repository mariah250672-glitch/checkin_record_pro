import 'package:checkin_record_pro/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches splash', (tester) async {
    await tester.pumpWidget(const CheckinApp());
    expect(find.text('签到记录器'), findsOneWidget);
  });
}
