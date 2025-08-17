import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class FFmpegService {
  /// MP4 ses dosyasını MP3'e çevirir
  static Future<bool> convertMp4ToMp3({
    required String inputPath,
    required String outputPath,
  }) async {
    try {
      if (!File(inputPath).existsSync()) {
        throw Exception("Input file not found: $inputPath");
      }

      // MP4 -> MP3
      final command = '-i "$inputPath" -q:a 0 -map a "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return returnCode?.isValueSuccess() ?? false;
    } catch (e) {
      print("convertMp4ToMp3 error: $e");
      return false;
    }
  }

  /// Video + Audio dosyasını birleştirir (MP4 çıkışı)
  static Future<bool> mergeAudioVideo({
    required String videoPath,
    required String audioPath,
    required String outputPath,
  }) async {
    try {
      if (!File(videoPath).existsSync()) {
        throw Exception("Video file not found: $videoPath");
      }
      if (!File(audioPath).existsSync()) {
        throw Exception("Audio file not found: $audioPath");
      }

      final command =
          '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      return returnCode?.isValueSuccess() ?? false;
    } catch (e) {
      print("mergeAudioVideo error: $e");
      return false;
    }
  }

  static Future<bool> isFFmpegAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return returnCode != null && ReturnCode.isSuccess(returnCode);
    } catch (e) {
      print("FFmpeg availability check failed: $e");
      return false;
    }
  }
}
