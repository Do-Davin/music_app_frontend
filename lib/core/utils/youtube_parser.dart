import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// A robust utility to extract YouTube video ID from various URL patterns,
/// including standard watch links, mobile links, embeds, shorts, and direct IDs.
String? extractYoutubeId(String input) {
  final cleanInput = input.trim();
  if (cleanInput.isEmpty) return null;

  // 1. Direct 11-character video ID
  if (cleanInput.length == 11 && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(cleanInput)) {
    return cleanInput;
  }

  // 2. Regex for various YouTube URL structures
  final regExp = RegExp(
    r'(?:https?:)?\/\/(?:[a-zA-Z0-9\-]+\.)?(?:youtube\.com|youtu\.be)\/(?:watch\?(?:.*&)?v=|embed\/|v\/|shorts\/)?([a-zA-Z0-9_-]{11})',
    caseSensitive: false,
  );

  final match = regExp.firstMatch(cleanInput);
  if (match != null && match.groupCount >= 1) {
    return match.group(1);
  }

  // 3. Fallback to youtube_player_flutter package's built-in parser
  return YoutubePlayer.convertUrlToId(cleanInput);
}
