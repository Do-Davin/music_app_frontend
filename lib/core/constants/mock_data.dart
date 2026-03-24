import 'package:flutter/material.dart';

// Basic Models for our App
class Song {
  final String title;
  final String artist;
  final String imageUrl;

  const Song({
    required this.title,
    required this.artist,
    required this.imageUrl,
  });
}

class Playlist {
  final String name;
  final String imageUrl;
  final List<Color>? gradientColors; // For items like "Liked Songs"

  const Playlist({
    required this.name,
    required this.imageUrl,
    this.gradientColors,
  });
}

class MockData {
  // Using generic high-quality placeholders. Replace URLs with your actual asset paths or real URLs later.

  static const List<Song> recentlyPlayed = [
    Song(
      title: 'Starboy',
      artist: 'The Weeknd',
      imageUrl: 'https://picsum.photos/seed/starboy/200',
    ),
    Song(
      title: 'Bad Guy',
      artist: 'Billie Eilish',
      imageUrl: 'https://picsum.photos/seed/badguy/200',
    ),
    Song(
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      imageUrl: 'https://picsum.photos/seed/shape/200',
    ),
  ];

  static const List<Song> recommended = [
    Song(
      title: 'Night Drive',
      artist: 'Various Artists',
      imageUrl: 'https://picsum.photos/seed/night/200',
    ),
    Song(
      title: 'Space Vibes',
      artist: 'Synthwave',
      imageUrl: 'https://picsum.photos/seed/space/200',
    ),
    Song(
      title: 'Coding Mode',
      artist: 'Lo-fi Beats',
      imageUrl: 'https://picsum.photos/seed/code/200',
    ),
  ];

  static const List<Song> madeForYou = [
    Song(
      title: 'Levitating',
      artist: 'Dua Lipa',
      imageUrl: 'https://picsum.photos/seed/dua/200',
    ),
    Song(
      title: 'Stay',
      artist: 'Justin Bieber',
      imageUrl: 'https://picsum.photos/seed/stay/200',
    ),
    Song(
      title: 'Calm Down',
      artist: 'Rema, Selena Gomez',
      imageUrl: 'https://picsum.photos/seed/calm/200',
    ),
  ];

  static const List<Playlist> favorites = [
    Playlist(
      name: 'Liked Songs',
      imageUrl: '',
      gradientColors: [Colors.purple, Colors.teal],
    ),
    Playlist(name: 'Top Hits', imageUrl: 'https://picsum.photos/seed/hits/200'),
    Playlist(
      name: 'Chill Mix',
      imageUrl: 'https://picsum.photos/seed/chill/200',
    ),
    Playlist(
      name: 'Workout',
      imageUrl: 'https://picsum.photos/seed/workout/200',
    ),
  ];

  static const List<Playlist> moods = [
    Playlist(
      name: 'Focus',
      imageUrl: 'https://picsum.photos/seed/focus/300/150',
    ),
    Playlist(
      name: 'Chill',
      imageUrl: 'https://picsum.photos/seed/chill2/300/150',
    ),
    Playlist(
      name: 'Sleep',
      imageUrl: 'https://picsum.photos/seed/sleep/300/150',
    ),
    Playlist(
      name: 'Workout',
      imageUrl: 'https://picsum.photos/seed/gym/300/150',
    ),
  ];

  static const List<String> popularArtistsUrls = [
    'https://picsum.photos/seed/artist1/200', // Billie Eilish
    'https://picsum.photos/seed/artist2/200', // Drake
    'https://picsum.photos/seed/artist3/200', // Taylor Swift
    'https://picsum.photos/seed/artist4/200', // Sabrina
  ];
}
