import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageDownloader {
  /// Downloads test car images for offline use
  static Future<void> downloadTestImages() async {
    if (!kDebugMode) return; // Only run in debug mode

    debugPrint('Starting to download test car images...');

    // Sample car images from the web
    final Map<String, String> imagesToDownload = {
      'mahindra_scorpio.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/129893/scorpio-classic-exterior-right-front-three-quarter-2.jpeg',
      'suzuki_swift.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/54399/swift-exterior-right-front-three-quarter-64.jpeg',
      'tata_nexon.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/144155/nexon-exterior-right-front-three-quarter-5.jpeg',
      'toyota_fortuner.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/44709/fortuner-exterior-right-front-three-quarter-19.jpeg',
      'bmw_x5.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/149477/x5-exterior-right-front-three-quarter-2.jpeg',
      'tesla_model3.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/42925/model-3-exterior-right-front-three-quarter.jpeg',
      'honda_city.jpg':
          'https://imgd.aeplcdn.com/664x374/n/cw/ec/134287/city-hybrid-exterior-right-front-three-quarter-2.jpeg',
    };

    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(path.join(appDir.path, 'car_images'));

      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Download images
      for (final entry in imagesToDownload.entries) {
        final fileName = entry.key;
        final url = entry.value;
        final file = File(path.join(imagesDir.path, fileName));

        // Skip if file already exists
        if (await file.exists()) {
          debugPrint('File $fileName already exists, skipping...');
          continue;
        }

        debugPrint('Downloading $fileName from $url');

        // Download and save the file
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('Successfully downloaded $fileName');
        } else {
          debugPrint('Failed to download $fileName: ${response.statusCode}');
        }
      }

      debugPrint('Test car images download completed');
    } catch (e) {
      debugPrint('Error downloading test images: $e');
    }
  }
}
