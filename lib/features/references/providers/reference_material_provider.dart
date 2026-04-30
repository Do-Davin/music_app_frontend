import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../models/reference_material.dart';
import '../services/reference_material_service.dart';

// ─── State ─────────────────────────────────────────────────────────────────

class ReferenceState {
  final List<ReferenceMaterial> materials;
  final bool isLoading;
  final String? error;
  final String selectedFilter; // 'All', 'PDF', 'PPT', 'Sheet Music', 'Note', 'Other'

  ReferenceState({
    this.materials = const [],
    this.isLoading = false,
    this.error,
    this.selectedFilter = 'All',
  });

  ReferenceState copyWith({
    List<ReferenceMaterial>? materials,
    bool? isLoading,
    String? error,
    String? selectedFilter,
  }) {
    return ReferenceState(
      materials: materials ?? this.materials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }

  // Returns filtered list based on selectedFilter
  List<ReferenceMaterial> get filtered {
    if (selectedFilter == 'All') return materials;
    return materials.where((m) => m.type == selectedFilter).toList();
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class ReferenceNotifier extends StateNotifier<ReferenceState> {
  final ReferenceMaterialService _service;

  ReferenceNotifier(this._service) : super(ReferenceState()) {
    fetchAll();
  }

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.fetchAll();
      state = state.copyWith(materials: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> create(Map<String, dynamic> input) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.create(input);
      await fetchAll(); // Refresh list after create
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> update(String id, Map<String, dynamic> input) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.update(id, input);
      await fetchAll(); // Refresh list after update
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> delete(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.delete(id);
      await fetchAll(); // Refresh list after delete
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

// You need to pass in your GraphQLClient. Adjust this to match how your app
// exposes the GraphQLClient (e.g. via a graphQLClientProvider).
final referenceMaterialServiceProvider = Provider<ReferenceMaterialService>(
  (ref) => ReferenceMaterialService(),
);

final referenceProvider = StateNotifierProvider<ReferenceNotifier, ReferenceState>((ref) {
  final service = ref.watch(referenceMaterialServiceProvider);
  return ReferenceNotifier(service);
});