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

void main() {
  testWidgets('User can open the scan screen and return without a diagnosis', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(imagePicker: TestImagePicker()));
    await tester.pumpAndSettle();

    expect(find.text('AgroShield'), findsOneWidget);

    await tester.ensureVisible(find.text('Start leaf scan'));
    await tester.tap(find.text('Start leaf scan'));
    await tester.pumpAndSettle();

    expect(find.text('Tomato leaf scan'), findsOneWidget);
    expect(find.text('No photo selected'), findsOneWidget);

    final analyseButton = find.byKey(const Key('analyseButton'));
    await tester.ensureVisible(analyseButton);

    expect(tester.widget<FilledButton>(analyseButton).onPressed, isNull);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('AgroShield'), findsOneWidget);
    expect(find.text('Start leaf scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
