import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/shared/widgets/success_popup.dart';

class FavoriteIconButton extends ConsumerStatefulWidget {
  final String songId;
  final bool initialIsFavorite;
  final VoidCallback? onToggle;
  final double iconSize;

  const FavoriteIconButton({
    Key? key,
    required this.songId,
    this.initialIsFavorite = false,
    this.onToggle,
    this.iconSize = 24,
  }) : super(key: key);

  @override
  ConsumerState<FavoriteIconButton> createState() => _FavoriteIconButtonState();
}

class _FavoriteIconButtonState extends ConsumerState<FavoriteIconButton> {
  late bool _isFavorite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
  }

  @override
  void didUpdateWidget(FavoriteIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIsFavorite != widget.initialIsFavorite) {
      _isFavorite = widget.initialIsFavorite;
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(toggleSongInLikedSongsProvider(widget.songId).future).then(
        (result) {
          setState(() {
            _isFavorite = result;
            _isLoading = false;
          });
          if (mounted) {
            SuccessPopup.show(
              context,
              title: result ? 'Liked' : 'Unliked',
              subtitle: result ? 'Added to Liked Songs' : 'Removed from Liked Songs',
              icon: result ? Icons.favorite : Icons.favorite_border,
              iconColor: result ? Colors.red : AppColors.hint,
            );
          }
          widget.onToggle?.call();
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleFavorite,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? Colors.red : AppColors.hint,
          size: widget.iconSize,
        ),
      ),
    );
  }
}
