import 'package:file_picker/file_picker.dart';

import 'local_backup_platform_io.dart'
    if (dart.library.html) 'local_backup_platform_web.dart' as platform;

Future<void> shareBackupText(String text, String subject) =>
    platform.shareBackupText(text, subject);

Future<List<int>?> readPickedFileBytes(PlatformFile f) =>
    platform.readPickedFileBytes(f);
