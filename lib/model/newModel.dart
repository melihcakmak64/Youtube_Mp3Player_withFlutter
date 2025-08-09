import 'package:equatable/equatable.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import "package:youtube_explode_dart/src/reverse_engineering/pages/watch_page.dart";

class ExtendedVideo extends Equatable {
  final VideoId id;
  final String title;
  final String author;
  final ChannelId channelId;
  final DateTime? uploadDate;
  final String? uploadDateRaw;
  final DateTime? publishDate;
  final String description;
  final Duration? duration;
  final ThumbnailSet thumbnails;
  final Iterable<String>? keywords;
  final Engagement engagement;
  final bool isLive;
  bool isDownloaded;
  bool isPlaying;
  bool isDownloading;
  final WatchPage? watchPage;
  final String url;

  ExtendedVideo({
    required this.id,
    required this.title,
    required this.author,
    required this.channelId,
    this.uploadDate,
    this.uploadDateRaw,
    this.publishDate,
    required this.description,
    this.duration,
    required this.thumbnails,
    this.keywords,
    required this.engagement,
    required this.isLive,
    this.isDownloaded = false,
    this.isPlaying = false,
    this.isDownloading = false,
    this.watchPage,
    required this.url,
  });

  ExtendedVideo copyWith({
    bool? isDownloaded,
    bool? isPlaying,
    bool? isDownloading,
  }) {
    return ExtendedVideo(
      id: id,
      title: title,
      author: author,
      channelId: channelId,
      uploadDate: uploadDate,
      uploadDateRaw: uploadDateRaw,
      publishDate: publishDate,
      description: description,
      duration: duration,
      thumbnails: thumbnails,
      keywords: keywords,
      engagement: engagement,
      isLive: isLive,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      isPlaying: isPlaying ?? this.isPlaying,
      isDownloading: isDownloading ?? this.isDownloading,
      watchPage: watchPage,
      url: url,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    author,
    channelId,
    uploadDate,
    uploadDateRaw,
    publishDate,
    description,
    duration,
    thumbnails,
    keywords,
    engagement,
    isLive,
    isDownloaded,
    isPlaying,
    isDownloading,
    watchPage,
    url,
  ];
}
