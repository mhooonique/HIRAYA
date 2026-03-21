// lib/features/marketplace/providers/marketplace_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';
import '../data/dummy_products.dart';

class MarketplaceState {
  final List<ProductModel> products;    // real only
  final List<ProductModel> allProducts; // real + dummy merged
  final List<ProductModel> trending;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String searchQuery;
  final String sortBy;

  MarketplaceState({
    this.products         = const [],
    this.allProducts      = const [],
    this.trending         = const [],
    this.isLoading        = false,
    this.error,
    this.selectedCategory = 'All',
    this.searchQuery      = '',
    this.sortBy           = 'newest',
  });

  MarketplaceState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? allProducts,
    List<ProductModel>? trending,
    bool?               isLoading,
    String?             error,
    String?             selectedCategory,
    String?             searchQuery,
    String?             sortBy,
  }) =>
      MarketplaceState(
        products:         products         ?? this.products,
        allProducts:      allProducts      ?? this.allProducts,
        trending:         trending         ?? this.trending,
        isLoading:        isLoading        ?? this.isLoading,
        error:            error,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        searchQuery:      searchQuery      ?? this.searchQuery,
        sortBy:           sortBy           ?? this.sortBy,
      );

  List<ProductModel> get filtered {
    var list = List<ProductModel>.from(allProducts);

    if (selectedCategory != 'All') {
      list = list.where((p) => p.category == selectedCategory).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.innovatorName.toLowerCase().contains(q)).toList();
    }

    switch (sortBy) {
      case 'most_liked':
        list.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'most_viewed':
        list.sort((a, b) => b.views.compareTo(a.views));
        break;
      case 'most_interest':
        list.sort((a, b) => b.interestCount.compareTo(a.interestCount));
        break;
      default:
        // Real posts newest first, dummy fills gaps
        final real  = list.where((p) => !isDummyProduct(p.id)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final dummy = list.where((p) =>  isDummyProduct(p.id)).toList();
        list = _interleave(real, dummy);
    }
    return list;
  }

  /// Interleave: show 2 real posts then 1 dummy to fill gaps naturally
  static List<ProductModel> _interleave(
      List<ProductModel> real, List<ProductModel> dummy) {
    final result = <ProductModel>[];
    int ri = 0, di = 0;
    while (ri < real.length || di < dummy.length) {
      if (ri < real.length) result.add(real[ri++]);
      if (ri < real.length) result.add(real[ri++]);
      if (di < dummy.length) result.add(dummy[di++]);
    }
    return result;
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final ApiService _api;

  MarketplaceNotifier(this._api) : super(MarketplaceState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // ✅ No leading slash — matches AppConfig.apiBaseUrl base
      final res = await _api.get('products', auth: false);
      if (res['success'] == true) {
        final realList = (res['data'] as List)
            .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
            .toList();
        final merged = [...realList, ...dummyProducts];
        state = state.copyWith(
          products:    realList,
          allProducts: merged,
          isLoading:   false,
        );
      } else {
        state = state.copyWith(
          products:    [],
          allProducts: dummyProducts,
          isLoading:   false,
          error:       res['message'] as String? ?? 'Failed to load products.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        products:    [],
        allProducts: dummyProducts,
        isLoading:   false,
        error:       'Could not connect. Showing demo content.',
      );
    }
  }

  void setCategory(String cat) => state = state.copyWith(selectedCategory: cat);
  void setSearch(String q)     => state = state.copyWith(searchQuery: q);
  void setSort(String s)       => state = state.copyWith(sortBy: s);

  Future<bool> likeProduct(int productId) async {
    if (isDummyProduct(productId)) return false;
    final snapshot = state.products;
    final updated = snapshot.map((p) {
      if (p.id == productId) {
        return ProductModel.fromJson({
          'id': p.id, 'name': p.name, 'description': p.description,
          'category': p.category, 'images': p.images,
          'likes': p.likes + 1, 'views': p.views,
          'interest_count': p.interestCount, 'status': p.status,
          'innovator_name': p.innovatorName,
          'innovator_username': p.innovatorUsername,
          'innovator_id': p.innovatorId,
          'kyc_status': p.kycStatus,
          'created_at': p.createdAt.toIso8601String(),
        });
      }
      return p;
    }).toList();
    state = state.copyWith(
        products: updated, allProducts: [...updated, ...dummyProducts]);
    try {
      // ✅ No leading slash
      await _api.post('products/$productId/like', {}, auth: true);
      return true;
    } catch (_) {
      state = state.copyWith(
          products: snapshot, allProducts: [...snapshot, ...dummyProducts]);
      return false;
    }
  }

  Future<bool> expressInterest(int productId) async {
    if (isDummyProduct(productId)) return false;
    try {
      // ✅ No leading slash
      final res = await _api.post('products/$productId/interest', {}, auth: true);
      return res['success'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleBookmark(int productId, {required bool add}) async {
    if (isDummyProduct(productId)) return false;
    try {
      if (add) {
        // ✅ No leading slash
        await _api.post('products/$productId/bookmark', {}, auth: true);
      } else {
        await _api.delete('products/$productId/bookmark', auth: true);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

final marketplaceProvider =
    StateNotifierProvider<MarketplaceNotifier, MarketplaceState>(
  (ref) => MarketplaceNotifier(ref.read(apiServiceProvider)),
);