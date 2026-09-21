import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agroshield_app/main.dart';

class TestImagePicker extends ImagePicker {
  @override
  Future<LostDataResponse> retrieveLostData() async {
    return LostDataResponse.empty();
  }
}

// Scroll first, then render the updated position before interacting.
Future<void> revealWidget(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);

  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );

  await tester.pumpAndSettle();

  expect(
    finder.hitTestable(),
    findsOneWidget,
    reason: 'The widget must be visible and reachable before interaction.',
  );
}

Future<void> openScan(WidgetTester tester) async {
  await tester.pumpWidget(MyApp(imagePicker: TestImagePicker()));
  await tester.pumpAndSettle();

  final startButton = find.text('Start leaf scan');

  await revealWidget(tester, startButton);
  await tester.tap(startButton.hitTestable());
  await tester.pumpAndSettle();

  expect(find.text('Leaf photo preview'), findsOneWidget);
}

Future<void> chooseOption(
  WidgetTester tester,
  Key fieldKey,
  String label,
) async {
  final field = find.byKey(fieldKey);

  await revealWidget(tester, field);
  await tester.tap(field.hitTestable());
  await tester.pumpAndSettle();

  final option = find.text(label).hitTestable();

  expect(
    option,
    findsOneWidget,
    reason: 'The open dropdown should contain the visible option "$label".',
  );

  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Changing category requires a new plant selection', (
    tester,
  ) async {
    await openScan(tester);

    final gallery = find.byKey(const Key('galleryButton'));

    expect(tester.widget<OutlinedButton>(gallery).onPressed, isNull);

    await chooseOption(tester, const Key('categoryField'), 'Vegetable plants');

    await chooseOption(
      tester,
      const ValueKey('plantField-vegetables'),
      'Tomato',
    );

    expect(find.text('Selected plant: Tomato'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(gallery).onPressed, isNotNull);

    await chooseOption(tester, const Key('categoryField'), 'Fruit plants');

    expect(find.text('Selected plant: Tomato'), findsNothing);
    expect(tester.widget<OutlinedButton>(gallery).onPressed, isNull);

    await chooseOption(tester, const ValueKey('plantField-fruits'), 'Banana');

    expect(find.text('Selected plant: Banana'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(gallery).onPressed, isNotNull);

    final analyse = find.byKey(const Key('analyseButton'));

    expect(tester.widget<FilledButton>(analyse).onPressed, isNull);

    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('AgroShield'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Custom plant name must contain more than whitespace', (
    tester,
  ) async {
    await openScan(tester);

    await chooseOption(tester, const Key('categoryField'), 'Other plants');

    await chooseOption(
      tester,
      const ValueKey('plantField-other'),
      'Other / enter name',
    );

    final name = find.byKey(const Key('customNameField'));
    final gallery = find.byKey(const Key('galleryButton'));

    await revealWidget(tester, name);
    await tester.enterText(name, '   ');
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(gallery).onPressed, isNull);

    await tester.enterText(name, 'Dragon fruit');
    await tester.pumpAndSettle();

    expect(find.text('Selected plant: Dragon fruit'), findsOneWidget);

    expect(tester.widget<OutlinedButton>(gallery).onPressed, isNotNull);

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('analyseButton')))
          .onPressed,
      isNull,
    );

    expect(tester.takeException(), isNull);
  });
}
