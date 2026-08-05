import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_shopping_app/shared/widgets/buttons/app_primary_button.dart';

void main() {
  testWidgets('calls onPressed when tapped and not loading', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AppPrimaryButton(label: 'ادامه', onPressed: () => tapped = true),
      ),
    );

    expect(find.text('ادامه'), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, isTrue);
  });

  testWidgets('shows a progress indicator and disables interaction while loading',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AppPrimaryButton(
          label: 'ادامه',
          isLoading: true,
          onPressed: () => tapped = true,
        ),
      ),
    );

    expect(find.text('ادامه'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    expect(tapped, isFalse);
  });
}
