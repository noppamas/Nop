import 'package:json_better_editor/files/document_files.dart';

/// In-memory [DocumentFiles] for tests.
class FakeDocumentFiles implements DocumentFiles {
  /// Files on the fake disk, by path.
  final Map<String, String> disk = {};

  /// Path the next open dialog returns; null means the user cancels.
  String? nextOpenPick;

  int openDialogCount = 0;
  String? lastOpenFilterLabel;

  @override
  Future<String?> pickJsonToOpen({required String filterLabel}) async {
    openDialogCount++;
    lastOpenFilterLabel = filterLabel;
    return nextOpenPick;
  }

  @override
  Future<String> readText(String path) async {
    final text = disk[path];
    if (text == null) throw Exception('No such file: $path');
    return text;
  }

  /// Path the next save dialog returns; null means the user cancels.
  String? nextSavePick;

  int saveDialogCount = 0;
  String? lastSuggestedName;

  /// Paths whose writes fail (for example, no permission).
  final Set<String> readOnly = {};

  int writeCount = 0;

  @override
  Future<String?> pickJsonSaveLocation({
    required String filterLabel,
    required String suggestedName,
  }) async {
    saveDialogCount++;
    lastSuggestedName = suggestedName;
    final pick = nextSavePick;
    return pick == null ? null : ensureJsonExtension(pick);
  }

  @override
  Future<void> writeText(String path, String text) async {
    if (readOnly.contains(path)) {
      throw Exception('Permission denied: $path');
    }
    writeCount++;
    disk[path] = text;
  }
}
