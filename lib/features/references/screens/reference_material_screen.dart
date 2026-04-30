import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reference_material.dart';
import '../providers/reference_material_provider.dart';

class ReferenceMaterialScreen extends ConsumerWidget {
  const ReferenceMaterialScreen({super.key});

  static const _filters = ['All', 'PDF', 'PPT', 'Sheet Music', 'Note', 'Other'];
  static const _types = ['PDF', 'PPT', 'Sheet Music', 'Note', 'Other'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(referenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reference Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(referenceProvider.notifier).fetchAll(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ── Filter chips ────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filters.map((f) {
                final selected = state.selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(referenceProvider.notifier).setFilter(f),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.error != null
                    ? Center(child: Text('Error: ${state.error}'))
                    : state.filtered.isEmpty
                        ? const Center(child: Text('No reference materials found.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: state.filtered.length,
                            itemBuilder: (context, index) {
                              final material = state.filtered[index];
                              return _MaterialCard(
                                material: material,
                                onEdit: () => _showForm(context, ref, material),
                                onDelete: () => _confirmDelete(context, ref, material),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ── Add / Edit form dialog ─────────────────────────────────────────────────
  void _showForm(BuildContext context, WidgetRef ref, ReferenceMaterial? existing) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final fileUrlCtrl = TextEditingController(text: existing?.fileUrl ?? '');
    final topicCtrl = TextEditingController(text: existing?.topic ?? '');
    String selectedType = existing?.type ?? 'PDF';

    showDialog(
      context: context,
      //isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              scrollable: true,
              title: Text(existing == null ? 'Add Material' : 'Edit Material'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Type *'),
                      items: _types
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => selectedType = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: topicCtrl,
                      decoration: const InputDecoration(labelText: 'Topic'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fileUrlCtrl,
                      decoration: const InputDecoration(labelText: 'File URL'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final input = {
                      'title': titleCtrl.text.trim(),
                      'type': selectedType,
                      if (topicCtrl.text.isNotEmpty) 'topic': topicCtrl.text.trim(),
                      if (descCtrl.text.isNotEmpty) 'description': descCtrl.text.trim(),
                      if (fileUrlCtrl.text.isNotEmpty) 'fileUrl': fileUrlCtrl.text.trim(),
                    };
                    if (existing == null) {
                      ref.read(referenceProvider.notifier).create(input);
                    } else {
                      ref.read(referenceProvider.notifier).update(existing.id, input);
                    }
                    Navigator.pop(context);
                  },
                  child: Text(existing == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Delete confirmation ────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context, WidgetRef ref, ReferenceMaterial material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(referenceProvider.notifier).delete(material.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Material Card Widget ──────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  final ReferenceMaterial material;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + type badge row
            Row(
              children: [
                Expanded(
                  child: Text(
                    material.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _typeColor(material.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    material.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: _typeColor(material.type),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            if (material.topic != null) ...[
              const SizedBox(height: 6),
              Text(
                'Topic: ${material.topic}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],

            if (material.description != null) ...[
              const SizedBox(height: 6),
              Text(material.description!),
            ],

            if (material.fileUrl != null) ...[
              const SizedBox(height: 6),
              Text(
                material.fileUrl!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'PDF':
        return Colors.red;
      case 'PPT':
        return Colors.orange;
      case 'Sheet Music':
        return Colors.purple;
      case 'Note':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}