import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PdfService {
  /// Pick a PDF file using the system file picker.
  /// Returns null if the user cancels.
  Future<PdfImportResult?> pickAndImportPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    return _importPdf(File(file.path!), file.name);
  }

  Future<PdfImportResult> _importPdf(File sourceFile, String fileName) async {
    // Copy to app documents directory
    final docsDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(docsDir.path, 'ai_tutor_pdfs'));
    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    final id = _uuid.v4();
    final destPath = p.join(pdfDir.path, '$id.pdf');
    await sourceFile.copy(destPath);

    // Get page count - we'll determine this from pdfrx at render time
    // For now, return the file info
    return PdfImportResult(
      localPath: destPath,
      originalName: fileName,
    );
  }

  /// Delete a locally stored PDF.
  Future<void> deletePdf(String localPath) async {
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class PdfImportResult {
  const PdfImportResult({
    required this.localPath,
    required this.originalName,
  });

  final String localPath;
  final String originalName;
}
