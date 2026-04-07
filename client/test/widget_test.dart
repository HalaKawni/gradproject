import 'package:client/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the login page on startup', (WidgetTester tester) async {
    await tester.pumpWidget(const LearnyApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
