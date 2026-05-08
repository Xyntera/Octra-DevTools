import 'package:flutter_test/flutter_test.dart';
import 'package:octra_devtools/main.dart';

void main() {
  testWidgets('renders Octra DevTools shell', (tester) async {
    await tester.pumpWidget(const OctraDevToolsApp());

    expect(find.text('Octra DevTools'), findsWidgets);
    expect(find.text('Compile AML'), findsOneWidget);
    expect(find.text('main.aml'), findsWidgets);
    expect(find.text('OCS01 Token'), findsWidgets);
    expect(find.text('Multisig'), findsWidgets);
    expect(find.text('AMM'), findsWidgets);
  });
}
