import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/auth/data/models/user.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/playlist/providers/playlist_provider.dart';
import 'package:music_app_frontend/features/profile/providers/profile_provider.dart';
import 'package:music_app_frontend/shared/widgets/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry points
// ─────────────────────────────────────────────────────────────────────────────

Future<void> showEditProfileSheet(
  BuildContext context, {
  required User currentUser,
}) {
  return _showProfileSheet(
    context,
    builder: (ctx) => _EditProfileSheet(currentUser: currentUser),
  );
}

Future<void> showNewPlaylistSheet(BuildContext context, WidgetRef ref) {
  return _showProfileSheet(
    context,
    builder: (ctx) => _NewPlaylistSheet(ref: ref),
  );
}

Future<void> showAccountTypeSheet(
  BuildContext context, {
  required User currentUser,
  required Future<void> Function() onSwitchToProfessional,
  required bool isSwitching,
}) {
  return _showProfileSheet(
    context,
    builder: (ctx) => _AccountTypeSheet(
      currentUser: currentUser,
      onSwitchToProfessional: onSwitchToProfessional,
      isSwitching: isSwitching,
    ),
  );
}

Future<void> showPrivacyVisibilitySheet(BuildContext context) {
  return _showProfileSheet(
    context,
    builder: (ctx) => const _PrivacyVisibilitySheet(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared shell
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showProfileSheet(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => _ProfileSheetShell(child: builder(ctx)),
  );
}

class _ProfileSheetShell extends StatelessWidget {
  const _ProfileSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.inputBorder,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title, {this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration _sheetInputDecoration({
  required String hint,
  bool hasError = false,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.hint, fontSize: 14),
    filled: true,
    fillColor: AppColors.card,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.inputBorder,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: hasError ? AppColors.error : AppColors.primary,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Profile
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.currentUser});

  final User currentUser;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Tracks the avatar URL locally after a successful upload so the preview
  // stays fresh inside the sheet without needing to close/reopen.
  String? _uploadedAvatarUrl;

  // Prevents re-entrant file picks while one is already in progress.
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentUser.username);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isUploadingImage =>
      ref.watch(profileImageUploadProvider).isLoading;

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(usernameUpdateProvider);
    final hasUpdateError = updateState.hasError;
    final isBusy = updateState.isLoading || _isUploadingImage || _isPickingFile;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle(
            'Edit profile',
            subtitle: 'Change your username or profile photo.',
          ),
          const SizedBox(height: 18),
          _AvatarEditPreview(
            avatarUrl: _uploadedAvatarUrl ?? widget.currentUser.effectiveAvatarUrl,
            username: widget.currentUser.username,
            isUploading: _isUploadingImage || _isPickingFile,
            onTap: isBusy ? null : _handleAvatarEditTap,
          ),
          const SizedBox(height: 18),
          Text(
            'Username',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            enabled: !isBusy,
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            onChanged: (_) {
              if (hasUpdateError) {
                ref.read(usernameUpdateProvider.notifier).clear();
              }
            },
            style: AppTextStyles.body.copyWith(fontSize: 15),
            decoration: _sheetInputDecoration(
              hint: 'Username',
              hasError: hasUpdateError,
            ),
            validator: _validateUsername,
          ),
          if (updateState.hasError) ...[
            const SizedBox(height: 10),
            Text(
              _normalizeError(updateState.error!),
              style: AppTextStyles.body.copyWith(
                color: AppColors.error,
                fontSize: 13,
              ),
              softWrap: true,
            ),
          ],
          const SizedBox(height: 22),
          _SheetActionRow(
            cancelLabel: 'Cancel',
            confirmLabel: 'Save',
            isLoading: updateState.isLoading,
            onCancel: isBusy ? () {} : () => Navigator.of(context).pop(),
            onConfirm: isBusy ? () {} : _save,
          ),
        ],
      ),
    );
  }

  Future<void> _handleAvatarEditTap() async {
    if (_isPickingFile || _isUploadingImage) return;

    setState(() => _isPickingFile = true);
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        // withData: true ensures bytes are populated on all platforms,
        // including iOS where path may be null for cloud-backed files.
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;

    // Prefer bytes (always available when withData:true); fall back to reading
    // the file from path if bytes are somehow absent.
    final List<int>? bytes;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      bytes = file.bytes!;
    } else if (file.path != null && file.path!.isNotEmpty) {
      try {
        // ignore: avoid_slow_async_io
        bytes = await _readFileBytes(file.path!);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Could not read the selected image. Please try another.'),
            ),
          );
        return;
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not access the selected image. Please try another.'),
          ),
        );
      return;
    }

    // Clear any previous upload error before re-trying.
    ref.read(profileImageUploadProvider.notifier).clear();

    final updatedUser = await ref
        .read(profileImageUploadProvider.notifier)
        .uploadImage(imageBytes: bytes, filename: file.name);

    if (!mounted) return;

    if (updatedUser == null) {
      final error = ref.read(profileImageUploadProvider).error;
      final message = error?.toString().replaceFirst('Exception: ', '') ??
          'Image upload failed. Please try again.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    setState(() => _uploadedAvatarUrl = updatedUser.effectiveAvatarUrl);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
  }

  Future<List<int>> _readFileBytes(String path) {
    return File(path).readAsBytes();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = await ref
        .read(usernameUpdateProvider.notifier)
        .updateUsername(
          currentUser: widget.currentUser,
          username: _controller.text,
        );

    if (!mounted || updatedUser == null) return;

    ref.invalidate(profileProvider);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Username updated.')));
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.length < 3) return 'Username must be at least 3 characters';
    if (username.length > 30) return 'Username cannot be longer than 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return 'Use only letters, numbers, and underscores';
    }
    return null;
  }

  String _normalizeError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('already taken') ||
        message.contains('already exists') ||
        message.contains('duplicate')) {
      return 'Username already taken';
    }
    if (message.contains('at least 3') ||
        message.contains('at least three') ||
        message.contains('too short')) {
      return 'Username must be at least 3 characters';
    }
    return 'Could not update username';
  }
}

class _AvatarEditPreview extends StatelessWidget {
  const _AvatarEditPreview({
    required this.avatarUrl,
    required this.username,
    required this.isUploading,
    required this.onTap,
  });

  final String? avatarUrl;
  final String username;
  final bool isUploading;
  final VoidCallback? onTap;

  static const double _radius = 46;

  String get _initials {
    final cleaned = username.trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  // Gap between the avatar edge and the inner ring, and between the two rings.
  static const double _innerGap = 3;
  static const double _outerGap = 3;

  @override
  Widget build(BuildContext context) {
    final hasUrl = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    // The tappable avatar with overlays.
    final avatarWithOverlay = Semantics(
      label: 'Change profile photo',
      button: true,
      child: Tooltip(
        message: 'Change profile photo',
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: isUploading ? null : onTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base avatar — network image or initials/icon fallback.
                CircleAvatar(
                  radius: _radius,
                  backgroundColor: AppColors.card,
                  backgroundImage: hasUrl ? NetworkImage(avatarUrl!) : null,
                  onBackgroundImageError: hasUrl
                      ? (exception, _) {
                          debugPrint(
                            '[AvatarEditPreview] Failed to load: $avatarUrl — $exception',
                          );
                        }
                      : null,
                  child: hasUrl
                      ? null
                      : (_initials.isNotEmpty
                            ? Text(
                                _initials,
                                style: AppTextStyles.subtitle.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 26,
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                color: AppColors.primary,
                                size: 36,
                              )),
                ),
                // Subtle scrim + centered outline camera icon.
                // Scrim is very light so the avatar content still reads clearly.
                // Icon color is white at ~60 % opacity — visible but not dominant.
                if (!isUploading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white.withValues(alpha: 0.62),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                // Upload spinner — replaces camera icon while busy.
                if (isUploading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    // Inner ring — slightly brighter white, sits just outside the avatar.
    final innerRingSize = (_radius + _innerGap) * 2;
    final innerRing = Container(
      width: innerRingSize,
      height: innerRingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
    );

    // Outer ring — dimmer white, sits just outside the inner ring.
    final outerRingSize = innerRingSize + _outerGap * 2;
    final outerRing = Container(
      width: outerRingSize,
      height: outerRingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
      ),
    );

    // Stack the rings behind the avatar so they don't clip it.
    return Center(
      child: SizedBox(
        width: outerRingSize,
        height: outerRingSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            outerRing,
            innerRing,
            avatarWithOverlay,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New Playlist
// ─────────────────────────────────────────────────────────────────────────────

class _NewPlaylistSheet extends StatefulWidget {
  const _NewPlaylistSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_NewPlaylistSheet> createState() => _NewPlaylistSheetState();
}

class _NewPlaylistSheetState extends State<_NewPlaylistSheet> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _controller.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await widget.ref.read(myPlaylistsProvider.notifier).createPlaylist(name);
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetTitle(
            'New playlist',
            subtitle: 'Group your practice tracks under a single name.',
          ),
          const SizedBox(height: 18),
          Text(
            'Playlist name',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            autofocus: true,
            enabled: !_isSubmitting,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: AppTextStyles.body.copyWith(fontSize: 15),
            decoration: _sheetInputDecoration(hint: 'My new playlist'),
            validator: (value) {
              final v = value?.trim() ?? '';
              if (v.isEmpty) return 'Name cannot be empty';
              if (v.length > 60) return 'Name is too long';
              return null;
            },
          ),
          const SizedBox(height: 22),
          _SheetActionRow(
            cancelLabel: 'Cancel',
            confirmLabel: 'Create',
            isLoading: _isSubmitting,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: _submit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Account Type
// ─────────────────────────────────────────────────────────────────────────────

class _AccountTypeSheet extends StatelessWidget {
  const _AccountTypeSheet({
    required this.currentUser,
    required this.onSwitchToProfessional,
    required this.isSwitching,
  });

  final User currentUser;
  final Future<void> Function() onSwitchToProfessional;
  final bool isSwitching;

  bool get _isProfessional =>
      currentUser.profileType == User.professionalProfileType;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetTitle(
          'Account type',
          subtitle: _isProfessional
              ? 'You are using a Professional account.'
              : 'You are using a Personal account.',
        ),
        const SizedBox(height: 18),
        _AccountTypeRow(
          icon: Icons.person_outline,
          title: 'Personal',
          description:
              'A friends/social account. Other users connect with you via friend requests.',
          isCurrent: !_isProfessional,
        ),
        const SizedBox(height: 10),
        _AccountTypeRow(
          icon: Icons.workspace_premium_outlined,
          title: 'Professional',
          description:
              'A public/follow account. Other users can follow you without sending a friend request.',
          isCurrent: _isProfessional,
        ),
        const SizedBox(height: 22),
        if (!_isProfessional)
          _SheetActionRow(
            cancelLabel: 'Close',
            confirmLabel: 'Switch to Professional',
            isLoading: isSwitching,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () async {
              Navigator.of(context).pop();
              await onSwitchToProfessional();
            },
          )
        else ...[
          Text(
            'Switching back to Personal is not supported yet.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.hint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Close',
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AccountTypeRow extends StatelessWidget {
  const _AccountTypeRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.isCurrent,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? AppColors.primary : AppColors.inputBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Current',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.hint,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy & Visibility (coming soon — no real backend support yet)
// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyVisibilitySheet extends StatelessWidget {
  const _PrivacyVisibilitySheet();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle(
          'Privacy & visibility',
          subtitle: 'Control who can find and interact with you.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coming soon',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Privacy & visibility controls are not available yet. '
                      'They will appear here once supported by the backend.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.hint,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              'Close',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared action row (Cancel / Confirm)
// ─────────────────────────────────────────────────────────────────────────────

class _SheetActionRow extends StatelessWidget {
  const _SheetActionRow({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.isLoading = false,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onSurface,
              side: const BorderSide(color: AppColors.inputBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(cancelLabel, style: AppTextStyles.button),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AppPrimaryButton(
            label: confirmLabel,
            isLoading: isLoading,
            onPressed: onConfirm,
          ),
        ),
      ],
    );
  }
}
