import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// File dialogs and disk access used by the editor. Tests swap in a fake.
abstract class DocumentFiles {
  /// Shows the macOS open dialog filtered to `.json`. Returns the chosen
  /// path, or null if the user cancelled.
  Future<String?> pickJsonToOpen({required String filterLabel});

  /// Reads a file as UTF-8 text.
  Future<String> readText(String path);

  /// Shows the macOS save dialog for a `.json` file. Returns the chosen
  /// path (always ending in `.json`), or null if the user cancelled.
  Future<String?> pickJsonSaveLocation({
    required String filterLabel,
    required String suggestedName,
  });

  /// Writes [text] to [path] as UTF-8, replacing the file.
  Future<void> writeText(String path, String text);
}

/// Adds a `.json` extension to [path] unless it already has one.
String ensureJsonExtension(String path) =>
    path.toLowerCase().endsWith('.json') ? path : '$path.json';

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

  @override
  Future<String?> pickJsonSaveLocation({
    required String filterLabel,
    required String suggestedName,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: filterLabel,
          extensions: const ['json'],
          uniformTypeIdentifiers: const ['public.json'],
        ),
      ],
    );
    return location == null ? null : ensureJsonExtension(location.path);
  }

  @override
  Future<void> writeText(String path, String text) =>
      File(path).writeAsString(text, flush: true);
}
