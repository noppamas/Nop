import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/app/app.dart';
import 'package:json_better_editor/editor/document_title.dart';
import 'package:json_better_editor/editor/toolbar/editor_toolbar.dart';
import 'package:json_better_editor/platform/native_window.dart';
import 'package:material_ui/material_ui.dart';

const leftGroup = [
  ToolbarKeys.newDocument,
  ToolbarKeys.open,
  ToolbarKeys.divider,
  ToolbarKeys.search,
];

const rightGroup = [
  ToolbarKeys.layoutTextOnly,
  ToolbarKeys.layoutNodeOnly,
  ToolbarKeys.layoutSplit,
  ToolbarKeys.language,
  ToolbarKeys.theme,
  ToolbarKeys.settings,
];

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const JsonEditorApp());
}

void main() {
  testWidgets('toolbar buttons are present in order, in two groups', (
    tester,
  ) async {
    await pumpApp(tester);

    final keys = [...leftGroup, ...rightGroup];
    final rects = [for (final key in keys) tester.getRect(find.byKey(key))];
    for (var i = 1; i < rects.length; i++) {
      expect(
        rects[i].left,
        greaterThan(rects[i - 1].right - 0.01),
        reason: '${keys[i]} should be right of ${keys[i - 1]}',
      );
    }

    // Left group hugs the left, right group hugs the right, gap in between.
    final screenWidth = tester.view.physicalSize.width;
    final leftEnd = tester.getRect(find.byKey(leftGroup.last)).right;
    final rightStart = tester.getRect(find.byKey(rightGroup.first)).left;
    expect(leftEnd, lessThan(screenWidth / 2));
    expect(rightStart, greaterThan(screenWidth / 2));
    expect(
      tester.getRect(find.byKey(ToolbarKeys.settings)).right,
      greaterThan(screenWidth - 20),
      reason: 'Settings is at the far right',
    );
  });

  testWidgets('toolbar leaves room for the macOS window controls', (
    tester,
  ) async {
    await pumpApp(tester);

    final first = tester.getRect(find.byKey(ToolbarKeys.newDocument));
    expect(first.left, greaterThanOrEqualTo(NativeWindow.windowControlsInset));
    expect(first.top, greaterThanOrEqualTo(0));
    expect(first.bottom, lessThanOrEqualTo(NativeWindow.titleBarHeight));
  });

  testWidgets('every button has an English tooltip', (tester) async {
    await pumpApp(tester);

    final expected = {
      ToolbarKeys.newDocument: 'New',
      ToolbarKeys.open: 'Open',
      ToolbarKeys.search: 'Search',
      ToolbarKeys.layoutTextOnly: 'Text only',
      ToolbarKeys.layoutNodeOnly: 'Node only',
      ToolbarKeys.layoutSplit: 'Split',
      ToolbarKeys.language: 'Language',
      ToolbarKeys.theme: 'Theme',
      ToolbarKeys.settings: 'Settings',
    };
    for (final entry in expected.entries) {
      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byKey(entry.key),
          matching: find.byType(Tooltip),
          matchRoot: true,
        ),
      );
      expect(tooltip.message, entry.value, reason: '${entry.key}');
    }
  });

  testWidgets('document title shows Untitled with no document open', (
    tester,
  ) async {
    await pumpApp(tester);

    final title = tester.widget<Text>(find.byKey(DocumentTitle.titleKey));
    expect(title.data, 'Untitled');
    // Title row sits under the toolbar.
    expect(
      tester.getRect(find.byKey(DocumentTitle.titleKey)).top,
      greaterThanOrEqualTo(NativeWindow.titleBarHeight),
    );
  });

  testWidgets('layout toggles select one layout, Split by default', (
    tester,
  ) async {
    await pumpApp(tester);

    bool selected(Key key) => tester
        .widget<IconButton>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(IconButton),
          ),
        )
        .isSelected!;

    expect(selected(ToolbarKeys.layoutSplit), isTrue);
    expect(selected(ToolbarKeys.layoutTextOnly), isFalse);

    await tester.tap(find.byKey(ToolbarKeys.layoutTextOnly));
    await tester.pump();
    expect(selected(ToolbarKeys.layoutTextOnly), isTrue);
    expect(selected(ToolbarKeys.layoutSplit), isFalse);
  });
}
