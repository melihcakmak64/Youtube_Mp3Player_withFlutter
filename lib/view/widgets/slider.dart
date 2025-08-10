import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_downloader/controller/controller_initializers.dart';
import 'package:youtube_downloader/helper/helper.dart';

class MusicSlider extends ConsumerWidget {
  MusicSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final musicPlayerState = ref.watch(musicPlayerProvider);
    final musicPlayerNotifier = ref.read(musicPlayerProvider.notifier);
    final currentPosition = musicPlayerState.currentPosition;
    final totalDuration = musicPlayerState.totalDuration;

    if (musicPlayerState.model == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(20),
        ),
        height: 70,
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(formatDuration(currentPosition)),
              Expanded(
                child: Slider(
                  value: currentPosition.inSeconds.toDouble().clamp(
                    0,
                    totalDuration.inSeconds.toDouble(),
                  ),
                  max: totalDuration.inSeconds.toDouble(),
                  onChanged: (value) {
                    musicPlayerNotifier.player.seek(
                      Duration(seconds: value.toInt()),
                    );
                  },
                ),
              ),
              Text(formatDuration(totalDuration)),
            ],
          ),
        ),
      ),
    );
  }
}
