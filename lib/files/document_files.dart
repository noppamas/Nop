import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// File dialogs and disk access used by the editor. Tests swap in a fake.
abstract class DocumentFiles {
  /// Shows the macOS open dialog filtered to `.json`. Returns the chosen
  /// path, or null if the user cancelled.
  Future<String?> pickJsonToOpen({required String filterLabel});

  /// Reads a file as UTF-8 text.
  Future<String> readText(String path);
}

/// The real implementation: macOS dialogs and `dart:io`.
class SystemDocumentFiles implements DocumentFiles {
  const SystemDocumentFiles();

  @override
  Future<String?> pickJsonToOpen({required String filterLabel}) async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: filterLabel,
          extensions: const ['json'],
          uniformTypeIdentifiers: const ['public.json'],
        ),
      ],
    );
    return file?.path;
  }

  @override
  Future<String> readText(String path) => File(path).readAsString();
}
