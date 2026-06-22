import 'dart:math';
import 'package:flutter/material.dart';

class Song {
  final String title;
  final String artist;
  final String imageUrl;
  final String lyricsSnippet;
  final String duration;

  Song({
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.lyricsSnippet,
  }) : duration = _generateRandomDuration();

  static String _generateRandomDuration() {
    final random = Random();
    int minutes = random.nextInt(3) + 2;
    int seconds = random.nextInt(60);
    return "-$minutes:${seconds.toString().padLeft(2, '0')}";
  }
}

class Playlist {
  final String name;
  final String imageUrl;
  final List<Color>? gradientColors;

  const Playlist({
    required this.name,
    required this.imageUrl,
    this.gradientColors,
  });
}

// Mock/demo data for screens that haven't been wired to the real backend yet.
// Image URLs are intentionally left empty — consumers should treat an empty
// imageUrl as "no cover" and render a local fallback (icon/gradient) instead
// of hitting random third-party image hosts that may rate-limit (e.g. 522).
class MockData {
  // --- Section 1: Recently Played ---
  static List<Song> recentlyPlayed = [
    Song(
      title: 'Starboy',
      artist: 'The Weeknd',
      imageUrl: '',
      lyricsSnippet: "I'm tryna put you in the worst mood, ah",
    ),
    Song(
      title: 'Bad Guy',
      artist: 'Billie Eilish',
      imageUrl: '',
      lyricsSnippet: "So you're a tough guy, like it really rough guy",
    ),
    Song(
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      imageUrl: '',
      lyricsSnippet: "The club isn't the best place to find a lover",
    ),
    Song(
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      imageUrl: '',
      lyricsSnippet: "I said, ooh, I'm blinded by the lights",
    ),
  ];

  // --- Section 2: Recommended ---
  static List<Song> recommended = [
    Song(
      title: 'Dandelions',
      artist: 'Ruth B.',
      imageUrl: '',
      lyricsSnippet: "Maybe it's the way you say my name",
    ),
    Song(
      title: 'As It Was',
      artist: 'Harry Styles',
      imageUrl: '',
      lyricsSnippet: "In this world, it's just us, you know it's not the same",
    ),
    Song(
      title: 'Cruel Summer',
      artist: 'Taylor Swift',
      imageUrl: '',
      lyricsSnippet: "It's a cruel summer, with you",
    ),
    Song(
      title: 'Flowers',
      artist: 'Miley Cyrus',
      imageUrl: '',
      lyricsSnippet: "I can buy myself flowers, write my name in the sand",
    ),
  ];

  // --- Section 3: Made For You ---
  static List<Song> madeForYou = [
    Song(
      title: 'Levitating',
      artist: 'Dua Lipa',
      imageUrl: '',
      lyricsSnippet: "I believe that you're for me, I feel it in our energy",
    ),
    Song(
      title: 'Stay',
      artist: 'Justin Bieber',
      imageUrl: '',
      lyricsSnippet: "I do the same thing I told you that I never would",
    ),
    Song(
      title: 'Calm Down',
      artist: 'Rema, Selena Gomez',
      imageUrl: '',
      lyricsSnippet: "Baby, calm down, calm down",
    ),
  ];

  // --- Section 4: Playlists (Added Rock Classics) ---
  static List<Playlist> favorites = [
    const Playlist(
      name: 'Liked Songs',
      imageUrl: '',
      gradientColors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
    ),
    const Playlist(name: 'Top Hits', imageUrl: ''),
    const Playlist(name: 'Chill Mix', imageUrl: ''),
    const Playlist(name: 'Rock Classics', imageUrl: ''),
  ];

  // --- Section 4b: Liked Songs (Mock - 5 songs) ---
  static List<Song> likedSongs = [
    Song(
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      imageUrl: '',
      lyricsSnippet: "I said, ooh, I'm blinded by the lights",
    ),
    Song(
      title: 'As It Was',
      artist: 'Harry Styles',
      imageUrl: '',
      lyricsSnippet: "In this world, it's just us",
    ),
    Song(
      title: 'Flowers',
      artist: 'Miley Cyrus',
      imageUrl: '',
      lyricsSnippet: "I can buy myself flowers",
    ),
    Song(
      title: 'Starboy',
      artist: 'The Weeknd',
      imageUrl: '',
      lyricsSnippet: "I'm tryna put you in the worst mood",
    ),
    Song(
      title: 'Levitating',
      artist: 'Dua Lipa',
      imageUrl: '',
      lyricsSnippet: "You want me, I want you, baby",
    ),
  ];

  // --- Section 5: Moods (Added Workout & Party) ---
  static List<Playlist> moods = [
    const Playlist(name: 'Focus', imageUrl: ''),
    const Playlist(name: 'Chill', imageUrl: ''),
    const Playlist(name: 'Workout', imageUrl: ''),
    const Playlist(name: 'Party', imageUrl: ''),
  ];

  static List<String> popularArtistsUrls = const [];
}
