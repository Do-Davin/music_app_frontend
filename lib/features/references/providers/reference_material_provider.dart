import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app_frontend/core/network/graphql_config.dart';
import '../models/reference_material.dart';
import '../services/reference_material_service.dart';

final referenceMaterialServiceProvider = Provider<ReferenceMaterialService>((ref) {
  // Use authenticated client for mutations
  return ReferenceMaterialService(GraphQLConfig.clientToQuery(authenticated: true));
});

class ReferenceMaterialState {
  final List<ReferenceMaterial> materials;
  final bool isLoading;
  final String? error;
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
    String? error,
    String? currentFilter,
  }) {
    return ReferenceMaterialState(
      materials: materials ?? this.materials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class ReferenceMaterialNotifier extends StateNotifier<ReferenceMaterialState> {
  final ReferenceMaterialService _service;

  ReferenceMaterialNotifier(this._service) : super(const ReferenceMaterialState());

  Future<void> fetchMaterials({String? type}) async {
    state = state.copyWith(isLoading: true, error: null, currentFilter: type);

    try {
      final materials = await _service.fetchAll(type: type);
      state = state.copyWith(materials: materials, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

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
      state = state.copyWith(
        materials: [material, ...state.materials],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

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
      
      final updatedMaterials = state.materials.map((m) {
        return m.id == id ? updatedMaterial : m;
      }).toList();

      state = state.copyWith(materials: updatedMaterials, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteMaterial(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.delete(id);
      if (success) {
        final remainingMaterials = state.materials.where((m) => m.id != id).toList();
        state = state.copyWith(materials: remainingMaterials, isLoading: false);
      } else {
        state = state.copyWith(error: 'Failed to delete material', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

final referenceMaterialProvider = StateNotifierProvider<ReferenceMaterialNotifier, ReferenceMaterialState>((ref) {
  final service = ref.watch(referenceMaterialServiceProvider);
  return ReferenceMaterialNotifier(service);
});
