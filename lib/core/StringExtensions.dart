extension FileNameSanitizer on String {
  String sanitize() {
    return replaceAll(RegExp(r'[<>:"/\\|?*]'), '').replaceAll('"', '').trim();
  }
}
