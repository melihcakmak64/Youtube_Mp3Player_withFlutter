import 'package:just_audio/just_audio.dart';
import 'package:music_player/model/newModel.dart';

class MusicPlayerService {
  final AudioPlayer audioPlayer = AudioPlayer();

  Future<void> playMusicFromUrl(String url) async {
    await audioPlayer.setUrl(url);
    audioPlayer.play();
  }

  Future<void> stop(ExtendedVideo video) async {
    video.isPlaying.value = false;
    await audioPlayer.stop();
  }

  bool isPlaying() {
    return audioPlayer.playing;
  }
}
