import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:family_shopping_app/shared/widgets/errors/app_empty_state.dart';
import 'package:family_shopping_app/shared/widgets/errors/app_error_view.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('shows the message and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppEmptyState(icon: Icons.inbox, message: 'هیچ موردی نیست'),
        ),
      );

      expect(find.text('هیچ موردی نیست'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('shows the action button only when both label and callback are given',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AppEmptyState(
            icon: Icons.inbox,
            message: 'خالی',
            actionLabel: 'افزودن',
            onAction: () => tapped = true,
          ),
        ),
      );

      expect(find.widgetWithText(OutlinedButton, 'افزودن'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'افزودن'));
      expect(tapped, isTrue);
    });
  });

  group('AppErrorView', () {
    testWidgets('shows a default friendly message, no raw error text', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppErrorView()));

      expect(find.text('مشکلی پیش آمد. دوباره تلاش کنید.'), findsOneWidget);
    });

    testWidgets('retry button calls onRetry when provided', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(home: AppErrorView(onRetry: () => retried = true)),
      );

      expect(find.widgetWithText(OutlinedButton, 'تلاش دوباره'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'تلاش دوباره'));
      expect(retried, isTrue);
    });

    testWidgets('no retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppErrorView()));
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });
}
