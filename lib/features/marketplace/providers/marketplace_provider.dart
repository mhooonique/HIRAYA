import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';

class MarketplaceState {
  final List<ProductModel> products;
  final List<ProductModel> trending;
  final bool isLoading;
  final String? error;
  final String selectedCategory;
  final String searchQuery;
  final String sortBy;

  MarketplaceState({
    this.products = const [],
    this.trending = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.sortBy = 'newest',
  });

  MarketplaceState copyWith({
    List<ProductModel>? products,
    List<ProductModel>? trending,
    bool? isLoading,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    String? sortBy,
  }) =>
      MarketplaceState(
        products: products ?? this.products,
        trending: trending ?? this.trending,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        selectedCategory: selectedCategory ?? this.selectedCategory,
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
      );

  List<ProductModel> get filtered {
    var list = List<ProductModel>.from(products);
    if (selectedCategory != 'All') {
      list = list.where((p) => p.category == selectedCategory).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.innovatorName.toLowerCase().contains(q))
          .toList();
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
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
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
      final res = await _api.get('/products', auth: false);
      if (res['success'] == true) {
        final list = (res['data'] as List)
            .map((j) => ProductModel.fromJson(j))
            .toList();
        state = state.copyWith(
          products: list.isEmpty ? _dummyProducts() : list,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to load products.');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, products: _dummyProducts());
    }
  }

  void setCategory(String cat) => state = state.copyWith(selectedCategory: cat);
  void setSearch(String q) => state = state.copyWith(searchQuery: q);
  void setSort(String s) => state = state.copyWith(sortBy: s);

  Future<void> likeProduct(int productId) async {
    try {
      await _api.post('/products/$productId/like', {}, auth: true);
      final updated = state.products.map((p) {
        if (p.id == productId) {
          return ProductModel.fromJson({
            'id': p.id,
            'name': p.name,
            'description': p.description,
            'category': p.category,
            'images': p.images,
            'likes': p.likes + 1,
            'views': p.views,
            'interest_count': p.interestCount,
            'status': p.status,
            'innovator_name': p.innovatorName,
            'innovator_username': p.innovatorUsername,
            'innovator_id': p.innovatorId,
            'kyc_status': p.kycStatus,
            'created_at': p.createdAt.toIso8601String(),
          });
        }
        return p;
      }).toList();
      state = state.copyWith(products: updated);
    } catch (_) {}
  }

  List<ProductModel> _dummyProducts() => [
        ProductModel(id: 1, name: 'Smart Rice Monitoring System', description: 'IoT-based system that monitors soil moisture, temperature, and nutrient levels in real-time to optimize rice yield.', category: 'Agriculture', images: [], likes: 142, views: 890, interestCount: 23, status: 'approved', innovatorName: 'Maria Santos', innovatorUsername: 'maria_santos', innovatorId: 1, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 5))),
        ProductModel(id: 2, name: 'Solar Water Purifier', description: 'Low-cost solar-powered water purification system designed for remote barangays without access to clean water.', category: 'Energy', images: [], likes: 98, views: 654, interestCount: 17, status: 'approved', innovatorName: 'Juan dela Cruz', innovatorUsername: 'juan_dc', innovatorId: 2, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 10))),
        ProductModel(id: 3, name: 'AI Diagnostic Tablet', description: 'Portable AI-powered diagnostic tool that assists rural health workers in detecting common diseases.', category: 'Healthcare', images: [], likes: 211, views: 1203, interestCount: 45, status: 'approved', innovatorName: 'Dr. Ana Reyes', innovatorUsername: 'dr_ana', innovatorId: 3, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 2))),
        ProductModel(id: 4, name: 'Bamboo Composite Panel', description: 'Structural building panels made from bamboo composites — stronger than concrete, 60% lighter.', category: 'Construction', images: [], likes: 76, views: 432, interestCount: 12, status: 'approved', innovatorName: 'Carlo Mendoza', innovatorUsername: 'carlo_m', innovatorId: 4, kycStatus: 'pending', createdAt: DateTime.now().subtract(const Duration(days: 15))),
        ProductModel(id: 5, name: 'Modular Ergonomic Desk', description: 'Height-adjustable modular desk system manufactured from recycled materials, designed for Filipino home offices.', category: 'Product Design', images: [], likes: 54, views: 321, interestCount: 8, status: 'approved', innovatorName: 'Liza Tan', innovatorUsername: 'liza_tan', innovatorId: 5, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 7))),
        ProductModel(id: 6, name: 'BarangayConnect App', description: 'Mobile platform connecting barangay officials with residents for announcements, permits, and emergency alerts.', category: 'Information Technology', images: [], likes: 189, views: 987, interestCount: 34, status: 'approved', innovatorName: 'Rico Bautista', innovatorUsername: 'rico_dev', innovatorId: 6, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ];
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>(
  (ref) => MarketplaceNotifier(ref.read(apiServiceProvider)),
);