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
  bool isDownloaded;
  bool isPlaying;
  bool isDownloading;
  final String url;

  ResponseModel({
    required this.id,
    required this.title,

    this.publishDate,
    required this.description,
    this.duration,
    required this.thumbnails,
    this.isDownloaded = false,
    this.isPlaying = false,
    this.isDownloading = false,
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
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isPlaying: isPlaying ?? this.isPlaying,
      isDownloading: isDownloading ?? this.isDownloading,
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
    isDownloaded,
    isPlaying,
    isDownloading,
    url,
  ];
}
