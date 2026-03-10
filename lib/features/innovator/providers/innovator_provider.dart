import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/product_model.dart';

class InnovatorState {
  final List<ProductModel> myProducts;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Map<String, int> stats;

  InnovatorState({
    this.myProducts = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    Map<String, int>? stats,
  }) : stats = stats ?? {'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0, 'totalLikes': 0, 'totalViews': 0, 'totalInterests': 0};

  InnovatorState copyWith({
    List<ProductModel>? myProducts,
    bool? isLoading,
    String? error,
    String? successMessage,
    Map<String, int>? stats,
  }) =>
      InnovatorState(
        myProducts: myProducts ?? this.myProducts,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        successMessage: successMessage,
        stats: stats ?? this.stats,
      );
}

class InnovatorNotifier extends StateNotifier<InnovatorState> {
  InnovatorNotifier() : super(InnovatorState()) {
    loadMyProducts();
  }

  Future<void> loadMyProducts() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ApiService.get('/innovator/products', auth: true);
      if (res.data['success'] == true) {
        final list = (res.data['data'] as List)
            .map((j) => ProductModel.fromJson(j))
            .toList();
        _computeStats(list);
        state = state.copyWith(myProducts: list, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, myProducts: _dummy());
        _computeStats(_dummy());
      }
    } catch (_) {
      final d = _dummy();
      _computeStats(d);
      state = state.copyWith(isLoading: false, myProducts: d);
    }
  }

  void _computeStats(List<ProductModel> list) {
    state = state.copyWith(stats: {
      'total': list.length,
      'approved': list.where((p) => p.status == 'approved').length,
      'pending': list.where((p) => p.status == 'pending').length,
      'rejected': list.where((p) => p.status == 'rejected').length,
      'totalLikes': list.fold(0, (s, p) => s + p.likes),
      'totalViews': list.fold(0, (s, p) => s + p.views),
      'totalInterests': list.fold(0, (s, p) => s + p.interestCount),
    });
  }

  Future<bool> submitProduct({
    required String name,
    required String description,
    required String category,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.post('/products', {
        'name': name,
        'description': description,
        'category': category,
        'images': [],
      }, auth: true);
      if (res.data['success'] == true) {
        await loadMyProducts();
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Product submitted for admin review.',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['message'] ?? 'Failed to submit.',
        );
        return false;
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Cannot connect to server.');
      return false;
    }
  }

  Future<bool> updateProduct(int id, String name, String description, String category) async {
    try {
      final res = await ApiService.put('/products/$id', {
        'name': name,
        'description': description,
        'category': category,
      });
      if (res.data['success'] == true) {
        await loadMyProducts();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void clearMessages() => state = state.copyWith(error: null, successMessage: null);

  List<ProductModel> _dummy() => [
        ProductModel(id: 1, name: 'Smart Rice Monitoring System', description: 'IoT-based soil monitoring for rice yield optimization.', category: 'Agriculture', images: [], likes: 142, views: 890, interestCount: 23, status: 'approved', innovatorName: 'You', innovatorUsername: 'me', innovatorId: 0, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 5))),
        ProductModel(id: 2, name: 'Hydroponic Sensor Array', description: 'Automated nutrient and pH monitoring for hydroponic farms.', category: 'Agriculture', images: [], likes: 34, views: 210, interestCount: 8, status: 'pending', innovatorName: 'You', innovatorUsername: 'me', innovatorId: 0, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 1))),
      ];
}

final innovatorProvider =
    StateNotifierProvider<InnovatorNotifier, InnovatorState>(
  (ref) => InnovatorNotifier(),
);