import 'package:just_audio/just_audio.dart';
import 'package:youtube_downloader/model/newModel.dart';

class MusicPlayerService {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playMusicFromUrl(String url) async {
    await audioPlayer.setUrl(url);
    audioPlayer.play();
  }

  Future<void> stop(ExtendedVideo video) async {
    video.isPlaying = false;
    await audioPlayer.stop();
  }

  bool isPlaying() {
    return audioPlayer.playing;
  }

  Future<void> seek(Duration duration) async {
    await audioPlayer.seek(duration);
  }

  Stream<Duration> getPositionStream() {
    return audioPlayer.positionStream;
  }

  Stream<Duration?> getDurationStream() {
    return audioPlayer.durationStream;
  }
}
