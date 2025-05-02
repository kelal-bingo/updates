import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main() async {
  const downloadUrl =
      'https://ayxgdzogfgcscstgvnzo.supabase.co/storage/v1/object/public/updates//Kelal_Bingo.exe';
  const targetFileName = 'Kelal_Bingo.exe';
  final backupFileName = 'Kelal_Bingo_Backup.exe';

  final currentDir = Directory.current.path;
  final tempPath = p.join(currentDir, 'Kelal_Bingo_New.exe');
  final targetPath = p.join(currentDir, targetFileName);
  final backupPath = p.join(currentDir, backupFileName);

  print('Updater: Starting download...');

  try {
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode == 200) {
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);
      print('Download complete.');

      if (File(targetPath).existsSync()) {
        File(targetPath).renameSync(backupPath);
      }

      File(tempPath).renameSync(targetPath);

      print('Update applied. Launching main app...');

      await Process.start(targetPath, []);
    } else {
      print('Failed to download file. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Updater failed: $e');
  }

  exit(0);
}
