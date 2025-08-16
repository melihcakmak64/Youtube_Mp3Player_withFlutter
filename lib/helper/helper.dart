import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String getExtensionFromFileName(String fileName) {
  final parts = fileName.split('.');
  if (parts.length > 1) {
    return parts.last.toLowerCase();
  }
  return '';
}

Future<String> streamToString(Stream<List<int>> stream) async {
  final bytes = await stream.fold<BytesBuilder>(BytesBuilder(), (
    builder,
    data,
  ) {
    builder.add(data);
    return builder;
  });
  return base64Encode(bytes.takeBytes()); // ✅ binary → base64 string
}

Stream<List<int>> stringToStream(String str) {
  final decoded = base64Decode(str); // ✅ string → binary
  return Stream.value(decoded);
}

String getVideoQualityLabel(VideoOnlyStreamInfo opt) {
  int? height;
  int? fps;

  height = opt.videoResolution.height;
  fps = opt.framerate.framesPerSecond.toInt();

  String quality = "Unknown Quality"; // default
  if (height >= 1080) {
    quality = "High Quality";
  } else if (height >= 480) {
    quality = "Medium Quality";
  } else {
    quality = "Low Quality";
  }

  return "$quality • ${opt.qualityLabel} • $fps fps";
}
