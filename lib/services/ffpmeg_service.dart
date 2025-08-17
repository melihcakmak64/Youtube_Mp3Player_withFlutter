import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';

class VideoService {
  /// MP4'ten MP3'e dönüştürme
  static Future<File> convertMp4ToMp3({
    required String inputPath,
    required String outputPath, // artık output path veriyoruz
  }) async {
    final command = '-i "$inputPath" -vn -acodec libmp3lame -y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    } else {
      throw Exception("MP3 conversion failed with code: $returnCode");
    }
  }

  /// Video ve audio birleştirme (MP4)
  static Future<File> mergeAudioVideo({
    required String videoPath,
    required String audioPath,
    required String outputPath, // artık output path veriyoruz
  }) async {
    // Video stream'i olduğu gibi al, audio stream'i AAC'e çevir
    final command =
        '-i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -y "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      return File(outputPath);
    } else {
      throw Exception("Video + Audio merge failed with code: $returnCode");
    }
  }
}
