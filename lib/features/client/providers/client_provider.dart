// lib/features/client/providers/client_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';

class ClientState {
  final List<ProductModel> wishlist;
  final List<ProductModel> bookmarks;
  final Set<int> likedIds;
  final bool isLoadingWishlist;
  final bool isLoadingBookmarks;

  const ClientState({
    this.wishlist = const [],
    this.bookmarks = const [],
    this.likedIds = const {},
    this.isLoadingWishlist = false,
    this.isLoadingBookmarks = false,
  });

  Set<int> get wishlistIds => wishlist.map((p) => p.id).toSet();
  Set<int> get bookmarkIds => bookmarks.map((p) => p.id).toSet();

  ClientState copyWith({
    List<ProductModel>? wishlist,
    List<ProductModel>? bookmarks,
    Set<int>? likedIds,
    bool? isLoadingWishlist,
    bool? isLoadingBookmarks,
  }) =>
      ClientState(
        wishlist: wishlist ?? this.wishlist,
        bookmarks: bookmarks ?? this.bookmarks,
        likedIds: likedIds ?? this.likedIds,
        isLoadingWishlist: isLoadingWishlist ?? this.isLoadingWishlist,
        isLoadingBookmarks: isLoadingBookmarks ?? this.isLoadingBookmarks,
      );
}

class ClientNotifier extends StateNotifier<ClientState> {
  final ApiService _api;
  ClientNotifier(this._api) : super(const ClientState()) {
    loadWishlist();
    loadBookmarks();
    loadLikes();
  }

  Future<void> loadWishlist() async {
    state = state.copyWith(isLoadingWishlist: true);
    try {
      final res = await _api.get('products/wishlist', auth: true);
      if (res['success'] == true) {
        final list = (res['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(wishlist: list, isLoadingWishlist: false);
      } else {
        state = state.copyWith(isLoadingWishlist: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingWishlist: false);
    }
  }

  Future<void> loadBookmarks() async {
    state = state.copyWith(isLoadingBookmarks: true);
    try {
      final res = await _api.get('products/bookmarks', auth: true);
      if (res['success'] == true) {
        final list = (res['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(bookmarks: list, isLoadingBookmarks: false);
      } else {
        state = state.copyWith(isLoadingBookmarks: false);
      }
    } catch (_) {
      state = state.copyWith(isLoadingBookmarks: false);
    }
  }

  Future<void> loadLikes() async {
    try {
      final res = await _api.get('products/likes', auth: true);
      if (res['success'] == true) {
        final ids = (res['data'] as List).map((e) => (e as num).toInt()).toSet();
        state = state.copyWith(likedIds: ids);
      }
    } catch (_) {}
  }

  Future<void> toggleLike(int productId) async {
    final liked = state.likedIds.contains(productId);
    // Optimistic update
    final newIds = Set<int>.from(state.likedIds);
    liked ? newIds.remove(productId) : newIds.add(productId);
    state = state.copyWith(likedIds: newIds);
    try {
      await _api.post('products/$productId/like', {}, auth: true);
    } catch (_) {
      // Revert
      final revert = Set<int>.from(state.likedIds);
      liked ? revert.add(productId) : revert.remove(productId);
      state = state.copyWith(likedIds: revert);
    }
  }

  Future<void> toggleWishlist(ProductModel p) async {
    final exists = state.wishlistIds.contains(p.id);
    // Optimistic update
    state = state.copyWith(
      wishlist: exists
          ? state.wishlist.where((x) => x.id != p.id).toList()
          : [...state.wishlist, p],
    );
    try {
      if (exists) {
        await _api.delete('products/${p.id}/wishlist', auth: true);
      } else {
        await _api.post('products/${p.id}/wishlist', {}, auth: true);
      }
    } catch (_) {
      // Revert on failure
      state = state.copyWith(
        wishlist: exists
            ? [...state.wishlist, p]
            : state.wishlist.where((x) => x.id != p.id).toList(),
      );
    }
  }

  Future<void> toggleBookmark(ProductModel p) async {
    final exists = state.bookmarkIds.contains(p.id);
    state = state.copyWith(
      bookmarks: exists
          ? state.bookmarks.where((x) => x.id != p.id).toList()
          : [...state.bookmarks, p],
    );
    try {
      if (exists) {
        await _api.delete('products/${p.id}/bookmark', auth: true);
      } else {
        await _api.post('products/${p.id}/bookmark', {}, auth: true);
      }
    } catch (_) {
      state = state.copyWith(
        bookmarks: exists
            ? [...state.bookmarks, p]
            : state.bookmarks.where((x) => x.id != p.id).toList(),
      );
    }
  }
}

final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>(
  (ref) => ClientNotifier(ref.read(apiServiceProvider)),
);
