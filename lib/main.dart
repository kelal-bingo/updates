// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main() async {
  const repo = 'kelal-bingo/updates';
  const targetFileName = 'Kelal_Bingo.exe';

  final currentDir = Directory.current.path;
  final tempPath = p.join(currentDir, 'Kelal_Bingo_New.exe');
  final targetPath = p.join(currentDir, targetFileName);

  print('UPDATE FOUND: Checking  download...');

  try {
    // Fetching the latest release details from GitHub
    final apiUrl = 'https://api.github.com/repos/$repo/releases/latest';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final assets = data['assets'] as List<dynamic>;

      // Find the asset by its name
      final asset = assets.firstWhere(
        (a) => a['name'] == targetFileName,
        orElse: () => throw 'Asset $targetFileName not found in release',
      );
      final downloadUrl = asset['browser_download_url'];

      print('Downloading update...');

      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode == 200) {
        final contentLength = streamedResponse.contentLength ?? 0;
        final file = File(tempPath);
        final sink = file.openWrite();
        int downloaded = 0;

        // Create a completion handler
        final completer = Completer<void>();

        // Start listening to the download stream
        streamedResponse.stream.listen(
          (chunk) {
            downloaded += chunk.length;
            sink.add(chunk);

            // Calculate the progress percentage
            if (contentLength != 0) {
              final progress = (downloaded / contentLength * 100)
                  .toStringAsFixed(1);
              stdout.write('\rDownloading: $progress%');
            }
          },
          onDone: () async {
            await sink.close();
            print('\nDownload complete.');

            // Replace the old file with the new one
            if (File(targetPath).existsSync()) {
              File(targetPath).deleteSync();
            }
            File(tempPath).renameSync(targetPath);

            print('Update applied. Launching main app...');
            await Process.start(targetPath, []);
            completer.complete();
            exit(0);
          },
          onError: (e) async {
            await sink.close();
            print('\nDownload error: $e');
            completer.completeError(e);
          },
          cancelOnError: true,
        );

        await completer;
      } else {
        print(
          'Failed to download file. Status code: ${streamedResponse.statusCode}',
        );
      }
    } else {
      print('Failed to get release info. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Updater failed: $e');
  }
}
