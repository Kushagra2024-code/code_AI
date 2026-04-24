import "package:ai_oa_practice/src/app.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  testWidgets("App bootstraps", (tester) async {
    await tester.pumpWidget(const AiOaPracticeApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.text("Sign in to continue"), findsOneWidget);
  });
}
