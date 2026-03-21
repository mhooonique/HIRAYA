// lib/features/search/providers/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../marketplace/data/dummy_products.dart';

class SearchFilters {
  final String query;
  final String? category;
  final String sortBy;

  const SearchFilters({
    this.query    = '',
    this.category,
    this.sortBy   = 'trending',
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    String? sortBy,
    bool clearCategory = false,
  }) {
    return SearchFilters(
      query:    query    ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      sortBy:   sortBy   ?? this.sortBy,
    );
  }

  bool get hasActiveFilters => category != null || sortBy != 'trending';

  int get activeFilterCount {
    int count = 0;
    if (category != null)     count++;
    if (sortBy != 'trending') count++;
    return count;
  }

  Map<String, String> toQueryParams() {
    return {
      if (query.isNotEmpty) 'q':        query,
      if (category != null) 'category': category!,
      'sort':                            sortBy,
    };
  }
}

class TrendingTopic {
  final String keyword;
  final int searchCount;
  final double changePercent;

  const TrendingTopic({
    required this.keyword,
    required this.searchCount,
    required this.changePercent,
  });

  factory TrendingTopic.fromJson(Map<String, dynamic> j) => TrendingTopic(
        keyword:       j['keyword']         ?? '',
        searchCount:   j['search_count']    ?? 0,
        changePercent: (j['change_percent'] ?? 0.0).toDouble(),
      );
}

class SearchState {
  final bool isLoading;
  final List<ProductModel> results;
  final List<ProductModel> trendingProducts;
  final List<TrendingTopic> trendingTopics;
  final List<String> searchHistory;
  final List<String> suggestions;
  final SearchFilters filters;
  final int totalResults;
  final int currentPage;
  final bool hasMore;
  final String? error;

  const SearchState({
    this.isLoading        = false,
    this.results          = const [],
    this.trendingProducts = const [],
    this.trendingTopics   = const [],
    this.searchHistory    = const [],
    this.suggestions      = const [],
    this.filters          = const SearchFilters(),
    this.totalResults     = 0,
    this.currentPage      = 1,
    this.hasMore          = false,
    this.error,
  });

  SearchState copyWith({
    bool?                isLoading,
    List<ProductModel>?  results,
    List<ProductModel>?  trendingProducts,
    List<TrendingTopic>? trendingTopics,
    List<String>?        searchHistory,
    List<String>?        suggestions,
    SearchFilters?       filters,
    int?                 totalResults,
    int?                 currentPage,
    bool?                hasMore,
    String?              error,
  }) {
    return SearchState(
      isLoading:        isLoading        ?? this.isLoading,
      results:          results          ?? this.results,
      trendingProducts: trendingProducts ?? this.trendingProducts,
      trendingTopics:   trendingTopics   ?? this.trendingTopics,
      searchHistory:    searchHistory    ?? this.searchHistory,
      suggestions:      suggestions      ?? this.suggestions,
      filters:          filters          ?? this.filters,
      totalResults:     totalResults     ?? this.totalResults,
      currentPage:      currentPage      ?? this.currentPage,
      hasMore:          hasMore          ?? this.hasMore,
      error:            error,
    );
  }

  bool get isIdle => !isLoading && filters.query.isEmpty && results.isEmpty;
}

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _api;
  static const _historyKey = 'hiraya_search_history';
  static const _maxHistory = 10;

  SearchNotifier(this._api) : super(const SearchState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);
    final prefs   = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];
    try {
      // ✅ No leading slash
      final res      = await _api.get('search/trending');
      final trending = (res['trending_products'] as List? ?? [])
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final topics   = (res['trending_topics'] as List? ?? [])
          .map((e) => TrendingTopic.fromJson(e as Map<String, dynamic>))
          .toList();

      // ✅ Merge real trending with dummy products for a richer idle view
      final mergedTrending = [
        ...trending,
        ...dummyProducts.take(6 - trending.length > 0 ? 6 - trending.length : 0),
      ];

      state = state.copyWith(
        isLoading:        false,
        trendingProducts: mergedTrending,
        trendingTopics:   topics.isNotEmpty ? topics : _dummyTopics(),
        searchHistory:    history,
      );
    } catch (_) {
      // Fallback to dummy content when offline
      state = state.copyWith(
        isLoading:        false,
        searchHistory:    history,
        trendingProducts: dummyProducts.take(6).toList(),
        trendingTopics:   _dummyTopics(),
      );
    }
  }

  Future<void> search({bool loadMore = false}) async {
    if (state.filters.query.isEmpty && !state.filters.hasActiveFilters) {
      state = state.copyWith(results: [], totalResults: 0);
      return;
    }
    final page = loadMore ? state.currentPage + 1 : 1;
    if (!loadMore) state = state.copyWith(isLoading: true, error: null);
    try {
      final params = {...state.filters.toQueryParams(), 'page': page.toString()};
      // ✅ No leading slash
      final res        = await _api.get('search', queryParams: params);
      final newResults = (res['products'] as List? ?? [])
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (state.filters.query.isNotEmpty && !loadMore) {
        await _addToHistory(state.filters.query);
      }

      // ✅ If API returns no results, search dummy products locally too
      final allResults = newResults.isEmpty
          ? _searchDummies(state.filters.query)
          : newResults;

      state = state.copyWith(
        isLoading:    false,
        results:      loadMore ? [...state.results, ...allResults] : allResults,
        totalResults: res['total'] ?? allResults.length,
        currentPage:  page,
        hasMore:      res['has_more'] ?? false,
      );
    } catch (_) {
      // On error, fall back to searching dummy products locally
      final dummyResults = _searchDummies(state.filters.query);
      state = state.copyWith(
        isLoading:    false,
        results:      loadMore ? state.results : dummyResults,
        totalResults: loadMore ? state.totalResults : dummyResults.length,
      );
    }
  }

  /// Search dummy products locally by name, description, category
  List<ProductModel> _searchDummies(String q) {
    if (q.isEmpty) return [];
    final lower = q.toLowerCase();
    return dummyProducts.where((p) =>
        p.name.toLowerCase().contains(lower) ||
        p.description.toLowerCase().contains(lower) ||
        p.category.toLowerCase().contains(lower) ||
        p.innovatorName.toLowerCase().contains(lower)).toList();
  }

  Future<void> getSuggestions(String query) async {
    if (query.length < 2) {
      state = state.copyWith(suggestions: []);
      return;
    }
    try {
      // ✅ No leading slash
      final res         = await _api.get('search/suggestions',
          queryParams: {'q': query});
      final suggestions = List<String>.from(res['suggestions'] ?? []);
      // Supplement with dummy product names if API returns few results
      if (suggestions.length < 3) {
        final dummySuggestions = dummyProducts
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .map((p) => p.name)
            .take(3)
            .toList();
        final merged = {...suggestions, ...dummySuggestions}.toList();
        state = state.copyWith(suggestions: merged);
      } else {
        state = state.copyWith(suggestions: suggestions);
      }
    } catch (_) {
      final dummy = dummyProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .map((p) => p.name)
          .take(5)
          .toList();
      state = state.copyWith(suggestions: dummy);
    }
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters, results: [], currentPage: 1);
    if (filters.query.isNotEmpty || filters.hasActiveFilters) search();
  }

  void setQuery(String q)     => updateFilters(state.filters.copyWith(query: q));
  void setSortBy(String sort) => updateFilters(state.filters.copyWith(sortBy: sort));

  void clearFilters() {
    state = state.copyWith(
        filters: SearchFilters(query: state.filters.query), results: []);
    if (state.filters.query.isNotEmpty) search();
  }

  void searchTrending(String keyword) =>
      updateFilters(SearchFilters(query: keyword));

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    state = state.copyWith(searchHistory: []);
  }

  Future<void> removeHistoryItem(String term) async {
    final prefs   = await SharedPreferences.getInstance();
    final history = List<String>.from(state.searchHistory)..remove(term);
    await prefs.setStringList(_historyKey, history);
    state = state.copyWith(searchHistory: history);
  }

  Future<void> _addToHistory(String term) async {
    final prefs   = await SharedPreferences.getInstance();
    final history = List<String>.from(state.searchHistory)
      ..remove(term)
      ..insert(0, term);
    if (history.length > _maxHistory) history.removeLast();
    await prefs.setStringList(_historyKey, history);
    state = state.copyWith(searchHistory: history);
  }

  List<TrendingTopic> _dummyTopics() => const [
        TrendingTopic(keyword: 'Solar energy',       searchCount: 1240, changePercent: 34.2),
        TrendingTopic(keyword: 'Smart farming',      searchCount: 980,  changePercent: 21.5),
        TrendingTopic(keyword: 'Telemedicine',       searchCount: 870,  changePercent: 18.9),
        TrendingTopic(keyword: 'IoT sensors',        searchCount: 740,  changePercent: 12.1),
        TrendingTopic(keyword: 'Coconut products',   searchCount: 620,  changePercent: 8.4),
        TrendingTopic(keyword: 'Water purification', searchCount: 590,  changePercent: -3.2),
        TrendingTopic(keyword: 'Drone delivery',     searchCount: 480,  changePercent: 45.7),
        TrendingTopic(keyword: 'Bamboo materials',   searchCount: 430,  changePercent: 5.1),
      ];
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(apiServiceProvider));
});