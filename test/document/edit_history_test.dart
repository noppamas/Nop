import 'package:flutter_test/flutter_test.dart';
import 'package:json_better_editor/document/edit_history.dart';

void main() {
  var now = DateTime(2026);
  EditHistory history() => EditHistory(clock: () => now);
  void wait(int ms) => now = now.add(Duration(milliseconds: ms));

  test('undo and redo walk back and forth', () {
    final h = history();
    h.record('a', 'ab'); // typing
    wait(2000);
    h.record('ab', 'ab\n'); // new line: its own step
    expect(h.undo('ab\n'), 'ab');
    expect(h.undo('ab'), 'a');
    expect(h.undo('a'), isNull);
    expect(h.redo('a'), 'ab');
    expect(h.redo('ab'), 'ab\n');
    expect(h.redo('ab\n'), isNull);
  });

  test('quick typing groups into one step; a pause starts a new one', () {
    final h = history();
    h.record('', 'a');
    wait(100);
    h.record('a', 'ab');
    wait(100);
    h.record('ab', 'abc');
    wait(1500);
    h.record('abc', 'abcd');
    expect(h.undo('abcd'), 'abc');
    expect(h.undo('abc'), '');
  });

  test('typing and deleting are separate steps', () {
    final h = history();
    h.record('', 'a');
    h.record('a', 'ab');
    h.record('ab', 'a'); // backspace
    h.record('a', ''); // backspace
    expect(h.undo(''), 'ab');
    expect(h.undo('ab'), '');
  });

  test('paste, cut and indent are never grouped', () {
    final h = history();
    h.record('x', 'x hello'); // paste
    h.record('x hello', 'x'); // cut
    h.record('x', '  x'); // indent
    expect(h.undo('  x'), 'x');
    expect(h.undo('x'), 'x hello');
    expect(h.undo('x hello'), 'x');
  });

  test('a new edit after undo clears redo', () {
    final h = history();
    h.record('a', 'a1');
    wait(2000);
    expect(h.undo('a1'), 'a');
    expect(h.canRedo, isTrue);
    h.record('a', 'a2');
    expect(h.canRedo, isFalse);
    expect(h.redo('a2'), isNull);
  });

  test('typing right after an undo is a new step', () {
    final h = history();
    h.record('', 'a');
    expect(h.undo('a'), '');
    h.record('', 'b');
    h.record('b', 'bc');
    expect(h.undo('bc'), '');
    expect(h.canUndo, isFalse);
  });

  test('clear forgets everything', () {
    final h = history();
    h.record('a', 'b');
    h.undo('b');
    h.clear();
    expect(h.canUndo, isFalse);
    expect(h.canRedo, isFalse);
  });

  test('edit classification', () {
    expect(classifyEdit('ab', 'aXb'), EditKind.typing);
    expect(classifyEdit('ก', 'กข'), EditKind.typing);
    expect(classifyEdit('a', 'a😀'), EditKind.typing);
    expect(classifyEdit('aXb', 'ab'), EditKind.deleting);
    expect(classifyEdit('a', 'a\n'), EditKind.other);
    expect(classifyEdit('a', 'aXY'), EditKind.other);
    expect(classifyEdit('aX', 'aY'), EditKind.other);
  });
}
