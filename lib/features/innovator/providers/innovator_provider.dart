// lib/features/innovator/providers/innovator_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';

class InnovatorState {
  final List<ProductModel> myProducts;
  final ProductModel?      draft;
  final bool               isLoading;
  final bool               isSavingDraft;
  final String?            error;
  final String?            successMessage;
  final Map<String, int>   stats;

  InnovatorState({
    this.myProducts    = const [],
    this.draft,
    this.isLoading     = false,
    this.isSavingDraft = false,
    this.error,
    this.successMessage,
    Map<String, int>? stats,
  }) : stats = stats ?? {
          'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0,
          'totalLikes': 0, 'totalViews': 0, 'totalInterests': 0,
        };

  InnovatorState copyWith({
    List<ProductModel>? myProducts,
    ProductModel?       draft,
    bool?               isLoading,
    bool?               isSavingDraft,
    String?             error,
    String?             successMessage,
    Map<String, int>?   stats,
    bool                clearDraft = false,
  }) => InnovatorState(
    myProducts:     myProducts     ?? this.myProducts,
    draft:          clearDraft ? null : (draft ?? this.draft),
    isLoading:      isLoading      ?? this.isLoading,
    isSavingDraft:  isSavingDraft  ?? this.isSavingDraft,
    error:          error,
    successMessage: successMessage,
    stats:          stats          ?? this.stats,
  );
}

class InnovatorNotifier extends StateNotifier<InnovatorState> {
  final ApiService _api;
  InnovatorNotifier(this._api) : super(InnovatorState()) {
    loadMyProducts();
    loadDraft();
  }

  Future<void> loadMyProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get('innovator/products', auth: true);
      if (res['success'] == true) {
        final list = (res['data'] as List).map((j) => ProductModel.fromJson(j)).toList();
        _computeStats(list);
        state = state.copyWith(myProducts: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadDraft() async {
    try {
      final res = await _api.get('products/my-draft', auth: true);
      if (res['success'] == true && res['data'] != null) {
        state = state.copyWith(draft: ProductModel.fromJson(res['data'] as Map<String, dynamic>));
      }
    } catch (_) {}
  }

  void _computeStats(List<ProductModel> list) {
    state = state.copyWith(stats: {
      'total':          list.length,
      'approved':       list.where((p) => p.status == 'approved').length,
      'pending':        list.where((p) => p.status == 'pending').length,
      'rejected':       list.where((p) => p.status == 'rejected').length,
      'totalLikes':     list.fold(0, (s, p) => s + p.likes),
      'totalViews':     list.fold(0, (s, p) => s + p.views),
      'totalInterests': list.fold(0, (s, p) => s + p.interestCount),
    });
  }

  Future<void> saveDraft({
    required String       name,
    required String       description,
    required String       category,
    required List<String> images,
    String? videoBase64,
    String? videoFilename,
    String? externalLink,
    String? qrImage,
  }) async {
    if (name.isEmpty && description.isEmpty) return;
    state = state.copyWith(isSavingDraft: true);
    try {
      final body = <String, dynamic>{
        'name': name, 'description': description, 'category': category,
        'images': images, 'is_draft': true,
        if (videoBase64   != null) 'video_base64':   videoBase64,
        if (videoFilename != null) 'video_filename':  videoFilename,
        if (externalLink  != null) 'external_link':   externalLink,
        if (qrImage       != null) 'qr_image':         qrImage,
      };
      final existing = state.draft;
      if (existing != null && existing.id > 0) {
        await _api.put('products/${existing.id}', body, auth: true);
      } else {
        final res = await _api.post('products', body, auth: true);
        if (res['success'] == true) await loadDraft();
      }
      state = state.copyWith(isSavingDraft: false);
    } catch (_) {
      state = state.copyWith(isSavingDraft: false);
    }
  }

  Future<bool> submitProduct({
    required String       name,
    required String       description,
    required String       category,
    required List<String> images,
    String? videoBase64,
    String? videoFilename,
    String? externalLink,
    String? qrImage,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final body = <String, dynamic>{
        'name': name, 'description': description, 'category': category,
        'images': images, 'is_draft': false,
        if (videoBase64   != null) 'video_base64':   videoBase64,
        if (videoFilename != null) 'video_filename':  videoFilename,
        if (externalLink  != null) 'external_link':   externalLink,
        if (qrImage       != null) 'qr_image':         qrImage,
      };
      final existing = state.draft;
      final Map<String, dynamic> res;
      if (existing != null && existing.id > 0) {
        res = await _api.put('products/${existing.id}', body, auth: true);
      } else {
        res = await _api.post('products', body, auth: true);
      }
      if (res['success'] == true) {
        await loadMyProducts();
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Innovation submitted for admin review.',
          clearDraft: true,
        );
        return true;
      }
      state = state.copyWith(isLoading: false, error: res['message'] ?? 'Failed to submit.');
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Cannot connect to server.');
      return false;
    }
  }

  Future<void> discardDraft() async {
    final existing = state.draft;
    if (existing == null) return;
    try {
      await _api.delete('products/${existing.id}/draft', auth: true);
    } catch (_) {}
    state = state.copyWith(clearDraft: true);
  }

  Future<bool> updateProduct(int id, String name, String description, String category) async {
    try {
      final res = await _api.put('products/$id', {'name': name, 'description': description, 'category': category}, auth: true);
      if (res['success'] == true) { await loadMyProducts(); return true; }
      return false;
    } catch (_) { return false; }
  }

  void clearMessages() => state = state.copyWith(error: null, successMessage: null);
}

final innovatorProvider = StateNotifierProvider<InnovatorNotifier, InnovatorState>(
  (ref) => InnovatorNotifier(ref.read(apiServiceProvider)),
);