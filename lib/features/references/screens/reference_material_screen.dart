import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/shared/widgets/file_preview_bottom_sheet.dart';
import 'package:music_app_frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:music_app_frontend/features/song/providers/song_provider.dart';
import '../providers/reference_material_provider.dart';
import '../models/reference_material.dart';

class ReferenceMaterialScreen extends ConsumerStatefulWidget {
  final String? songId;
  /// Set to false when embedding inside a bottom sheet (hides the AppBar)
  final bool showAppBar;

  const ReferenceMaterialScreen({
    super.key,
    this.songId,
    this.showAppBar = true,
  });

  @override
  ConsumerState<ReferenceMaterialScreen> createState() => _ReferenceMaterialScreenState();
}

class _ReferenceMaterialScreenState extends ConsumerState<ReferenceMaterialScreen> {
  String? _selectedFilter;
  String _sortBy = 'newest'; // newest, oldest, alphabetical

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(referenceMaterialProvider.notifier).fetchMaterials(songId: widget.songId);
    });
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => _MaterialFormDialog(songId: widget.songId),
    );
  }

  void _showEditDialog(ReferenceMaterial material) {
    showDialog(
      context: context,
      builder: (context) => _MaterialFormDialog(material: material, songId: widget.songId),
    );
  }

  void _applyFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    ref.read(referenceMaterialProvider.notifier).fetchMaterials(type: filter, songId: widget.songId);
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Sort by',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSortOption('Newest First', 'newest'),
          _buildSortOption('Oldest First', 'oldest'),
          _buildSortOption('Alphabetical (A-Z)', 'alphabetical'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade400,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  List<ReferenceMaterial> _filterMaterials(List<ReferenceMaterial> materials) {
    var filtered = materials.toList();
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'alphabetical':
        filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return filtered;
  }

  String get _sortLabel {
    switch (_sortBy) {
      case 'newest':
        return 'Newest';
      case 'oldest':
        return 'Oldest';
      case 'alphabetical':
        return 'A-Z';
      default:
        return 'Newest';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceMaterialProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;

    final meAsync = ref.watch(meProvider);
    final songAsync = widget.songId != null ? ref.watch(songByIdProvider(widget.songId!)) : null;

    final currentUserId = meAsync.valueOrNull?.id;
    final songUserId = songAsync?.valueOrNull?.userId;

    final bool canManage = currentUserId != null && songUserId != null && currentUserId == songUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Reference Materials'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', null, Icons.grid_on),
                const SizedBox(width: 8),
                _buildFilterChip('PDF', 'PDF', Icons.picture_as_pdf),
                const SizedBox(width: 8),
                _buildFilterChip('PPT', 'PPT', Icons.slideshow),
                const SizedBox(width: 8),
                _buildFilterChip('Sheet Music', 'Sheet Music', Icons.music_note),
                const SizedBox(width: 8),
                _buildFilterChip('Note', 'Note', Icons.note),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Materials (${_filterMaterials(state.materials).length})',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth > 600 ? 18.0 : 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                InkWell(
                  onTap: _showSortOptions,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          _sortLabel,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildList(state, canManage),
          ),
        ],
      ),
      floatingActionButton: canManage ? FloatingActionButton(
        heroTag: 'referenceMaterialFAB',
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildList(ReferenceMaterialState state, bool canManage) {
    if (state.isLoading && state.materials.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.materials.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(referenceMaterialProvider.notifier).fetchMaterials(type: _selectedFilter, songId: widget.songId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredMaterials = _filterMaterials(state.materials);
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 ? 24.0 : 16.0;

    if (filteredMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            const Text(
              'No materials yet',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (canManage) ...[
              const SizedBox(height: 8),
              Text(
                'Tap + to add your first material',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 80,
      ),
      itemCount: filteredMaterials.length,
      itemBuilder: (context, index) {
        final material = filteredMaterials[index];
        return _MaterialCard(
          material: material,
          canManage: canManage,
          onEdit: () => _showEditDialog(material),
          onDelete: () => _confirmDelete(material.id),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String? value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF9800) : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF9800) : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _applyFilter(value),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(referenceMaterialProvider.notifier).deleteMaterial(id);
    }
  }
}

class _MaterialCard extends StatelessWidget {
  final ReferenceMaterial material;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _getFileIcon() {
    switch (material.type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
        return Icons.slideshow;
      case 'sheet music':
        return Icons.music_note;
      case 'note':
        return Icons.note;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor() {
    switch (material.type.toLowerCase()) {
      case 'pdf':
        return const Color(0xFFE53935);
      case 'ppt':
        return const Color(0xFFFF6F00);
      case 'sheet music':
        return const Color(0xFF7C4DFF);
      case 'note':
        return const Color(0xFF42A5F5);
      default:
        return Colors.grey;
    }
  }

  void _showPreview(BuildContext context) {
    if (material.fileUrl == null && material.fileName == null) return;
    final previewFile = PreviewFile(
      name: material.fileName ?? material.title,
      type: material.type,
      remoteUrl: material.fileUrl,
    );
    showFilePreview(context, file: previewFile);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth > 600 ? 64.0 : 56.0;
    final titleFontSize = screenWidth > 600 ? 18.0 : 16.0;
    final descFontSize = screenWidth > 600 ? 14.0 : 13.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: material.fileUrl != null ? () => _showPreview(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: _getFileIconColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFileIcon(),
                      color: _getFileIconColor(),
                      size: iconSize * 0.55,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.title,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (material.topic != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  material.topic!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Text(
                              material.timeAgo,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (canManage) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 22),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
              if (material.description != null && material.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  material.description!,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: descFontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (material.fileName != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showPreview(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.insert_drive_file,
                            size: 24,
                            color: _getFileIconColor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.fileName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${material.formattedFileSize} • ${material.type}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.visibility_outlined,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialFormDialog extends ConsumerStatefulWidget {
  final ReferenceMaterial? material;
  final String? songId;

  const _MaterialFormDialog({this.material, this.songId});

  @override
  ConsumerState<_MaterialFormDialog> createState() => _MaterialFormDialogState();
}

class _MaterialFormDialogState extends ConsumerState<_MaterialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _topicController;
  String _selectedType = 'PDF';
  File? _selectedFile;
  bool _isDragging = false;

  final List<String> _allowedExtensions = ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'txt', 'jpg', 'png'];
  final List<String> _materialTypes = ['PDF', 'PPT', 'Sheet Music', 'Note', 'Other'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.material?.title ?? '');
    _descriptionController = TextEditingController(text: widget.material?.description ?? '');
    _topicController = TextEditingController(text: widget.material?.topic ?? '');
    final initialType = widget.material?.type ?? 'PDF';
    _selectedType = _materialTypes.contains(initialType) ? initialType : 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  void _handleFileSelection(String? path) {
    if (path == null) return;
    final extension = path.split('.').last.toLowerCase();
    if (_allowedExtensions.contains(extension)) {
      setState(() {
        _selectedFile = File(path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid file type. Allowed: ${_allowedExtensions.join(', ')}')),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: _allowedExtensions);
    if (result != null && result.files.single.path != null) {
      _handleFileSelection(result.files.single.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(referenceMaterialProvider.notifier);
    try {
      if (widget.material == null) {
        await notifier.createMaterial(
          title: _titleController.text,
          type: _selectedType,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          file: _selectedFile,
          songId: widget.songId,
          topic: _topicController.text.isEmpty ? null : _topicController.text,
        );
      } else {
        await notifier.updateMaterial(
          id: widget.material!.id,
          title: _titleController.text,
          type: _selectedType,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          file: _selectedFile,
          songId: widget.songId,
          topic: _topicController.text.isEmpty ? null : _topicController.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
      content: DropTarget(
        onDragDone: (detail) {
          if (detail.files.isNotEmpty) _handleFileSelection(detail.files.first.path);
        },
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _isDragging ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            border: _isDragging ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'Enter material title'),
                    validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _materialTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(labelText: 'Topic', hintText: 'e.g., Music Theory, Practice Tips'),
                  ),
                  const SizedBox(height: 24),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isDragging ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: _isDragging ? AppColors.primary.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 48, color: _isDragging ? AppColors.primary : Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile == null ? 'Drag and drop file here or click to browse' : 'File selected (Click to change)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _isDragging ? AppColors.primary : Colors.grey, fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal),
                            ),
                            const SizedBox(height: 4),
                            Text('Allowed: PDF, PPT, Word, Images', style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.withValues(alpha: 0.3))),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_selectedFile!.path.split(Platform.pathSeparator).last, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ] else if (widget.material?.fileName != null) ...[
                    const SizedBox(height: 12),
                    Text('Current file: ${widget.material!.fileName}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white), child: Text(widget.material == null ? 'Create Material' : 'Update Material')),
      ],
    );
  }
}
