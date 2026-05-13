import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/constants/app_colors.dart';
import 'package:music_app_frontend/features/references/widgets/file_preview_bottom_sheet.dart';
import '../providers/reference_material_provider.dart';
import '../models/reference_material.dart';

class ReferenceMaterialScreen extends ConsumerStatefulWidget {
  const ReferenceMaterialScreen({super.key});

  @override
  ConsumerState<ReferenceMaterialScreen> createState() => _ReferenceMaterialScreenState();
}

class _ReferenceMaterialScreenState extends ConsumerState<ReferenceMaterialScreen> {
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(referenceMaterialProvider.notifier).fetchMaterials();
    });
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => const _MaterialFormDialog(),
    );
  }

  void _showEditDialog(ReferenceMaterial material) {
    showDialog(
      context: context,
      builder: (context) => _MaterialFormDialog(material: material),
    );
  }

  void _applyFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
    });
    ref.read(referenceMaterialProvider.notifier).fetchMaterials(type: filter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referenceMaterialProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reference Materials'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildFilterChip('All', null),
                _buildFilterChip('PDF', 'PDF'),
                _buildFilterChip('PPT', 'PPT'),
                _buildFilterChip('Sheet Music', 'Sheet Music'),
                _buildFilterChip('Note', 'Note'),
                _buildFilterChip('Other', 'Other'),
              ],
            ),
          ),
          
          // Materials list
          Expanded(
            child: _buildList(state),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildList(ReferenceMaterialState state) {
    if (state.isLoading && state.materials.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            ElevatedButton(
              onPressed: () => ref.read(referenceMaterialProvider.notifier).fetchMaterials(type: _selectedFilter),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.materials.isEmpty) {
      return const Center(child: Text('No materials found', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      itemCount: state.materials.length,
      itemBuilder: (context, index) {
        final material = state.materials[index];
        return _MaterialCard(
          material: material,
          onEdit: () => _showEditDialog(material),
          onDelete: () => _confirmDelete(material.id),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _applyFilter(value),
        selectedColor: AppColors.primary.withValues(alpha: 0.3),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.white70,
        ),
        backgroundColor: AppColors.surface,
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.onEdit,
    required this.onDelete,
  });

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
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(  // Makes whole card slightly tappable
        onTap: material.fileUrl != null ? () => _showPreview(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  material.type,
                  style: TextStyle(color: AppColors.primary, fontSize: 12),
                ),
              ),
              if (material.topic != null) ...[
                const SizedBox(height: 8),
                Text('Topic: ${material.topic}', style: const TextStyle(color: Colors.white60)),
              ],
              if (material.description != null) ...[
                const SizedBox(height: 8),
                Text(material.description!, style: const TextStyle(color: Colors.white70)),
              ],

              // === FILE PREVIEW SECTION (Clickable) ===
              if (material.fileName != null) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showPreview(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, size: 20, color: Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                material.fileName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${material.formattedFileSize} • ${material.mimeType ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 12, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.visibility, color: Colors.white70),
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

  const _MaterialFormDialog({this.material});

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
    
    // Ensure selected type is in the list of allowed types
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
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );

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
          topic: _topicController.text.isEmpty ? null : _topicController.text,
        );
      } else {
        await notifier.updateMaterial(
          id: widget.material!.id,
          title: _titleController.text,
          type: _selectedType,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          file: _selectedFile,
          topic: _topicController.text.isEmpty ? null : _topicController.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.material == null ? 'Add Material' : 'Edit Material'),
      content: DropTarget(
        onDragDone: (detail) {
          if (detail.files.isNotEmpty) {
            _handleFileSelection(detail.files.first.path);
          }
        },
        onDragEntered: (_) => setState(() => _isDragging = true),
        onDragExited: (_) => setState(() => _isDragging = false),
        child: Container(
          width: 400, // Fixed width for better layout on desktop
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
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter material title',
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: _materialTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional description',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _topicController,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      hintText: 'e.g., Music Theory, Practice Tips',
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Drop Zone
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
                          color: _isDragging 
                              ? AppColors.primary.withValues(alpha: 0.05) 
                              : Colors.white.withValues(alpha: 0.02),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined, 
                              size: 48, 
                              color: _isDragging ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFile == null 
                                  ? 'Drag and drop file here or click to browse'
                                  : 'File selected (Click to change)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isDragging ? AppColors.primary : Colors.grey,
                                fontWeight: _isDragging ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Allowed: PDF, PPT, Word, Images',
                              style: TextStyle(fontSize: 10, color: Colors.grey.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  if (_selectedFile != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFile!.path.split(Platform.pathSeparator).last,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (widget.material?.fileName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Current file: ${widget.material!.fileName}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.material == null ? 'Create Material' : 'Update Material'),
        ),
      ],
    );
  }
}
