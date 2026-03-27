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

class MockData {
  // --- Section 1: Recently Played ---
  static List<Song> recentlyPlayed = [
    Song(
      title: 'Starboy',
      artist: 'The Weeknd',
      imageUrl: 'https://picsum.photos/seed/starboy/400/400',
      lyricsSnippet: "I'm tryna put you in the worst mood, ah",
    ),
    Song(
      title: 'Bad Guy',
      artist: 'Billie Eilish',
      imageUrl: 'https://picsum.photos/seed/badguy/400/400',
      lyricsSnippet: "So you're a tough guy, like it really rough guy",
    ),
    Song(
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      imageUrl: 'https://picsum.photos/seed/shapeofyou/400/400',
      lyricsSnippet: "The club isn't the best place to find a lover",
    ),
    Song(
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      imageUrl: 'https://picsum.photos/seed/blinding/400/400',
      lyricsSnippet: "I said, ooh, I'm blinded by the lights",
    ),
  ];

  // --- Section 2: Recommended ---
  static List<Song> recommended = [
    Song(
      title: 'Dandelions',
      artist: 'Ruth B.',
      imageUrl: 'https://picsum.photos/seed/dandelions/400/400',
      lyricsSnippet: "Maybe it's the way you say my name",
    ),
    Song(
      title: 'As It Was',
      artist: 'Harry Styles',
      imageUrl: 'https://picsum.photos/seed/asitwas/400/400',
      lyricsSnippet: "In this world, it's just us, you know it's not the same",
    ),
    Song(
      title: 'Cruel Summer',
      artist: 'Taylor Swift',
      imageUrl: 'https://picsum.photos/seed/cruelsummer/400/400',
      lyricsSnippet: "It's a cruel summer, with you",
    ),
    Song(
      title: 'Flowers',
      artist: 'Miley Cyrus',
      imageUrl: 'https://picsum.photos/seed/flowers/400/400',
      lyricsSnippet: "I can buy myself flowers, write my name in the sand",
    ),
  ];

  // --- Section 3: Made For You ---
  static List<Song> madeForYou = [
    Song(
      title: 'Levitating',
      artist: 'Dua Lipa',
      imageUrl: 'https://picsum.photos/seed/levitating/400/400',
      lyricsSnippet: "I believe that you're for me, I feel it in our energy",
    ),
    Song(
      title: 'Stay',
      artist: 'Justin Bieber',
      imageUrl: 'https://picsum.photos/seed/stay/400/400',
      lyricsSnippet: "I do the same thing I told you that I never would",
    ),
    Song(
      title: 'Calm Down',
      artist: 'Rema, Selena Gomez',
      imageUrl: 'https://picsum.photos/seed/calmdown/400/400',
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
    const Playlist(
      name: 'Top Hits',
      imageUrl: 'https://picsum.photos/seed/hits99/200/200',
    ),
    const Playlist(
      name: 'Chill Mix',
      imageUrl: 'https://picsum.photos/seed/chill99/200/200',
    ),
    const Playlist(
      name: 'Rock Classics',
      imageUrl: 'https://picsum.photos/seed/rock77/200/200',
    ),
  ];

  // --- Section 5: Moods (Added Workout & Party) ---
  static List<Playlist> moods = [
    const Playlist(
      name: 'Focus',
      imageUrl: 'https://picsum.photos/seed/focus99/300/150',
    ),
    const Playlist(
      name: 'Chill',
      imageUrl: 'https://picsum.photos/seed/relax99/300/150',
    ),
    const Playlist(
      name: 'Workout',
      imageUrl: 'https://picsum.photos/seed/gym88/300/150',
    ),
    const Playlist(
      name: 'Party',
      imageUrl: 'https://picsum.photos/seed/party55/300/150',
    ),
  ];

  static List<String> popularArtistsUrls = [
    'https://picsum.photos/seed/artistA/200/200',
    'https://picsum.photos/seed/artistB/200/200',
    'https://picsum.photos/seed/artistC/200/200',
    'https://picsum.photos/seed/artistD/200/200',
  ];
}
