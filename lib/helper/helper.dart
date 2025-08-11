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
