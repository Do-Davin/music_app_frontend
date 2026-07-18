import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reference_material.dart';
import '../services/reference_material_service.dart';

final referenceMaterialServiceProvider = Provider<ReferenceMaterialService>((
  ref,
) {
  return ReferenceMaterialService();
});

// Sentinel used in copyWith to distinguish "reset to null" from "keep existing".
const _keep = Object();

class ReferenceMaterialState {
  final List<ReferenceMaterial> materials;
  final bool isLoading;
  final String? error;
  /// The active type filter, or null if showing all materials.
  final String? currentFilter;

  const ReferenceMaterialState({
    this.materials = const [],
    this.isLoading = false,
    this.error,
    this.currentFilter,
  });

  ReferenceMaterialState copyWith({
    List<ReferenceMaterial>? materials,
    bool? isLoading,
    // Use Object? + sentinel so callers can explicitly reset to null.
    Object? error = _keep,
    Object? currentFilter = _keep,
  }) {
    return ReferenceMaterialState(
      materials: materials ?? this.materials,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _keep) ? this.error : error as String?,
      currentFilter: identical(currentFilter, _keep)
          ? this.currentFilter
          : currentFilter as String?,
    );
  }
}

class ReferenceMaterialNotifier extends StateNotifier<ReferenceMaterialState> {
  final ReferenceMaterialService _service;

  ReferenceMaterialNotifier(this._service)
      : super(const ReferenceMaterialState());

  // ── Fetch ────────────────────────────────────────────────────────

  Future<void> fetchMaterials({String? type, String? songId}) async {
    // Explicitly pass null so the sentinel sees it as "reset to null"
    state = state.copyWith(
      isLoading: true,
      error: null,
      currentFilter: type,
    );

    try {
      final materials = await _service.fetchAll(type: type, songId: songId);
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ── Create ───────────────────────────────────────────────────────

  Future<void> createMaterial({
    required String title,
    required String type,
    String? description,
    File? file,
    String? songId,
    String? topic,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final material = await _service.create(
        title: title,
        type: type,
        description: description,
        file: file,
        songId: songId,
        topic: topic,
      );
      // Prepend the new material so it appears at the top of the list.
      state = state.copyWith(
        materials: [material, ...state.materials],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // ── Update ───────────────────────────────────────────────────────

  Future<void> updateMaterial({
    required String id,
    String? title,
    String? type,
    String? description,
    File? file,
    String? songId,
    String? topic,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedMaterial = await _service.update(
        id: id,
        title: title,
        type: type,
        description: description,
        file: file,
        songId: songId,
        topic: topic,
      );

      state = state.copyWith(
        materials: state.materials
            .map((m) => m.id == id ? updatedMaterial : m)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // ── Delete ───────────────────────────────────────────────────────

  Future<void> deleteMaterial(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.delete(id);
      if (success) {
        state = state.copyWith(
          materials: state.materials.where((m) => m.id != id).toList(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          error: 'Delete returned false — the server did not confirm deletion.',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  /// Clear any error from state without triggering a re-fetch.
  void clearError() {
    state = state.copyWith(error: null);
  }
}

final referenceMaterialProvider = StateNotifierProvider<
    ReferenceMaterialNotifier, ReferenceMaterialState>((ref) {
  final service = ref.watch(referenceMaterialServiceProvider);
  return ReferenceMaterialNotifier(service);
});
