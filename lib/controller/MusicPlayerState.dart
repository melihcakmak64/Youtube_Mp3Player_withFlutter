import 'package:youtube_downloader/model/ResponseModel.dart';

import 'package:equatable/equatable.dart';

class MusicPlayerState extends Equatable {
  final ResponseModel? model;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;

  const MusicPlayerState({
    required this.model,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
  });

  MusicPlayerState copyWith({
    ResponseModel? model,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return MusicPlayerState(
      model: model ?? this.model,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  @override
  List<Object?> get props => [
    model?.url,
    isPlaying,
    currentPosition,
    totalDuration,
  ];
}
