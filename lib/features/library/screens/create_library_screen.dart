import 'package:flutter/material.dart';

class CreateLibrarySheet extends StatelessWidget {
  const CreateLibrarySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Essential for BottomSheets
        children: [
          // The little drag handle line
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          _buildActionItem(
            icon: Icons.music_note,
            iconColor: Colors.orange,
            title: 'Playlist',
            subtitle: 'Create a playlist with a song',
          ),
          _buildActionItem(
            icon: Icons.people_outline,
            iconColor: Colors.amber,
            title: 'Collaborative playlist',
            subtitle: 'Create a playlist together',
          ),
          _buildActionItem(
            icon: Icons.bolt,
            iconColor: Colors.purpleAccent,
            title: 'Jam',
            subtitle: 'Listen together from anywhere',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white10,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
