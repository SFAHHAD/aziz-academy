import 'dart:io';

import 'package:file_picker/file_picker.dart' show PlatformFile;
import 'package:share_plus/share_plus.dart';

Future<void> shareBackupText(String text, String subject) =>
    Share.share(text, subject: subject);

Future<List<int>?> readPickedFileBytes(PlatformFile f) async {
  if (f.bytes != null) return f.bytes;
  if (f.path != null) {
    return File(f.path!).readAsBytes();
  }
  return null;
}
