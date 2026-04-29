import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/core/constants/app_text_styles.dart';
import 'package:music_app_frontend/features/practice_session/models/practice_session.dart';
import 'package:music_app_frontend/features/practice_session/providers/practice_session_provider.dart';
import 'package:music_app_frontend/shared/widgets/app_confirm_dialog.dart';
import 'package:music_app_frontend/shared/widgets/app_error_widget.dart';
import 'package:music_app_frontend/shared/widgets/app_loading_widget.dart';
import 'package:music_app_frontend/shared/widgets/app_text_field.dart';

class PracticeSessionScreen extends ConsumerWidget {
  const PracticeSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(practiceSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Practice Sessions'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(practiceSessionsProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Add',
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const _PracticeSessionFormDialog(),
            ),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: sessionsState.when(
        loading: () => const Center(child: AppLoadingWidget()),
        error: (err, _) => AppErrorWidget(
          message: 'Failed to load practice sessions. Please try again.',
          retryButtonText: 'Retry',
          onRetry: () => ref.read(practiceSessionsProvider.notifier).refresh(),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No practice sessions yet.\nTap + to add your first one.',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[400]),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _PracticeSessionCard(
              session: sessions[index],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _PracticeSessionFormDialog(),
        ),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}

class _PracticeSessionCard extends ConsumerWidget {
  const _PracticeSessionCard({required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = DateFormat.yMMMd().format(session.practiceDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.title,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _PracticeSessionFormDialog(existing: session),
                ),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () async {
                  final confirmed = await showConfirmDialog(
                    context: context,
                    title: 'Delete Practice Session',
                    message:
                        'Are you sure you want to delete "${session.title}"?',
                    confirmText: 'Delete',
                    cancelText: 'Cancel',
                  );
                  if (!confirmed) return;
                  await ref
                      .read(practiceSessionsProvider.notifier)
                      .deleteSession(session.id);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _Chip(label: dateLabel, icon: Icons.calendar_today_outlined),
              _Chip(
                label: '${session.duration} min',
                icon: Icons.timer_outlined,
              ),
              _Chip(
                label: session.focusArea,
                icon: Icons.music_note_outlined,
              ),
              _Chip(label: 'Rating ${session.rating}/5', icon: Icons.star),
            ],
          ),
          if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              session.notes!.trim(),
              style: AppTextStyles.body.copyWith(color: Colors.grey[300]),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeSessionFormDialog extends ConsumerStatefulWidget {
  const _PracticeSessionFormDialog({this.existing});

  final PracticeSession? existing;

  @override
  ConsumerState<_PracticeSessionFormDialog> createState() =>
      _PracticeSessionFormDialogState();
}

class _PracticeSessionFormDialogState
    extends ConsumerState<_PracticeSessionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _notes;

  DateTime _date = DateTime.now();
  String _focusArea = 'GENERAL';
  int _rating = 3;

  static const _focusAreas = <String>[
    'KARAOKE',
    'VOCAL',
    'TIMING',
    'LYRICS',
    'GENERAL',
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _duration = TextEditingController(
      text: existing != null ? existing.duration.toString() : '',
    );
    _notes = TextEditingController(text: existing?.notes ?? '');
    _date = existing?.practiceDate ?? DateTime.now();
    _focusArea = existing?.focusArea ?? 'GENERAL';
    _rating = existing?.rating ?? 3;
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Session' : 'Add Session',
        style: AppTextStyles.subtitle.copyWith(color: AppColors.onSurface),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _title,
                hint: 'Title',
                prefixIcon: Icons.title,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked == null) return;
                  setState(() => _date = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month,
                          color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat.yMMMd().format(_date),
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _duration,
                hint: 'Duration (minutes)',
                prefixIcon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final value = int.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Enter a valid duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    _focusAreas.contains(_focusArea) ? _focusArea : 'GENERAL',
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category, color: AppColors.primary),
                ),
                dropdownColor: AppColors.surface,
                items: _focusAreas
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _focusArea = v ?? 'GENERAL'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _rating,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.star, color: AppColors.primary),
                ),
                dropdownColor: AppColors.surface,
                items: [1, 2, 3, 4, 5]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text('$v'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _rating = v ?? 3),
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _notes,
                hint: 'Notes (optional)',
                prefixIcon: Icons.notes_outlined,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () async {
            if (!(_formKey.currentState?.validate() ?? false)) return;

            final title = _title.text.trim();
            final duration = int.parse(_duration.text.trim());
            final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();

            final controller = ref.read(practiceSessionsProvider.notifier);
            if (isEdit) {
              await controller.updateSession(
                widget.existing!.id,
                title: title,
                practiceDate: _date,
                duration: duration,
                focusArea: _focusArea,
                rating: _rating,
                notes: notes,
              );
            } else {
              await controller.create(
                title: title,
                practiceDate: _date,
                duration: duration,
                focusArea: _focusArea,
                rating: _rating,
                notes: notes,
              );
            }

            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEdit ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}

