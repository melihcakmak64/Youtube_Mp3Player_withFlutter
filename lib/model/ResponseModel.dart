import 'package:equatable/equatable.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import "package:youtube_explode_dart/src/reverse_engineering/pages/watch_page.dart";

class ResponseModel extends Equatable {
  final VideoId id;
  final String title;
  final DateTime? publishDate;
  final String description;
  final Duration? duration;
  final ThumbnailSet thumbnails;
  final String url;

  ResponseModel({
    required this.id,
    required this.title,

    this.publishDate,
    required this.description,
    this.duration,
    required this.thumbnails,
    required this.url,
  });

  ResponseModel copyWith({
    bool? isDownloaded,
    bool? isPlaying,
    bool? isDownloading,
  }) {
    return ResponseModel(
      id: id,
      title: title,
      publishDate: publishDate,
      description: description,
      duration: duration,
      thumbnails: thumbnails,
      url: url,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    publishDate,
    description,
    duration,
    thumbnails,
    url,
  ];
}
