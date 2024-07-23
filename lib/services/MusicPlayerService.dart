import 'package:just_audio/just_audio.dart';

class MusicPlayerService {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playMusicFromUrl(String url) async {
    await audioPlayer.setUrl(url);
    audioPlayer.play();
  }

  Future<void> stop() async {
    await audioPlayer.stop();
  }

  bool isPlaying() {
    return audioPlayer.playing;
  }
}
