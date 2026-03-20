// lib/features/search/providers/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class SearchFilters {
  final String query;
  final String? category;
  final String? stage; // concept | prototype | mvp | market_ready
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String sortBy; // trending | newest | rating | price_asc | price_desc | most_liked
  final List<String> tags;
  final bool showOnlyVerified;
  final bool showOnlyAvailable;

  const SearchFilters({
    this.query = '',
    this.category,
    this.stage,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.sortBy = 'trending',
    this.tags = const [],
    this.showOnlyVerified = false,
    this.showOnlyAvailable = false,
  });

  SearchFilters copyWith({
    String? query,
    String? category,
    String? stage,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    List<String>? tags,
    bool? showOnlyVerified,
    bool? showOnlyAvailable,
    bool clearCategory = false,
    bool clearStage = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinRating = false,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      stage: clearStage ? null : (stage ?? this.stage),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      sortBy: sortBy ?? this.sortBy,
      tags: tags ?? this.tags,
      showOnlyVerified: showOnlyVerified ?? this.showOnlyVerified,
      showOnlyAvailable: showOnlyAvailable ?? this.showOnlyAvailable,
    );
  }

  bool get hasActiveFilters =>
      category != null ||
      stage != null ||
      minPrice != null ||
      maxPrice != null ||
      minRating != null ||
      tags.isNotEmpty ||
      showOnlyVerified ||
      showOnlyAvailable ||
      sortBy != 'trending';

  int get activeFilterCount {
    int count = 0;
    if (category != null) count++;
    if (stage != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (tags.isNotEmpty) count += tags.length;
    if (showOnlyVerified) count++;
    if (showOnlyAvailable) count++;
    if (sortBy != 'trending') count++;
    return count;
  }

  Map<String, dynamic> toQueryParams() {
    return {
      if (query.isNotEmpty) 'q': query,
      if (category != null) 'category': category,
      if (stage != null) 'stage': stage,
      if (minPrice != null) 'min_price': minPrice.toString(),
      if (maxPrice != null) 'max_price': maxPrice.toString(),
      if (minRating != null) 'min_rating': minRating.toString(),
      'sort': sortBy,
      if (tags.isNotEmpty) 'tags': tags.join(','),
      if (showOnlyVerified) 'verified': '1',
      if (showOnlyAvailable) 'available': '1',
    };
  }
}

class TrendingTopic {
  final String keyword;
  final int searchCount;
  final double changePercent; // positive = trending up

  const TrendingTopic({
    required this.keyword,
    required this.searchCount,
    required this.changePercent,
  });

  factory TrendingTopic.fromJson(Map<String, dynamic> j) => TrendingTopic(
        keyword: j['keyword'] ?? '',
        searchCount: j['search_count'] ?? 0,
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
    this.isLoading = false,
    this.results = const [],
    this.trendingProducts = const [],
    this.trendingTopics = const [],
    this.searchHistory = const [],
    this.suggestions = const [],
    this.filters = const SearchFilters(),
    this.totalResults = 0,
    this.currentPage = 1,
    this.hasMore = false,
    this.error,
  });

  SearchState copyWith({
    bool? isLoading,
    List<ProductModel>? results,
    List<ProductModel>? trendingProducts,
    List<TrendingTopic>? trendingTopics,
    List<String>? searchHistory,
    List<String>? suggestions,
    SearchFilters? filters,
    int? totalResults,
    int? currentPage,
    bool? hasMore,
    String? error,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      trendingProducts: trendingProducts ?? this.trendingProducts,
      trendingTopics: trendingTopics ?? this.trendingTopics,
      searchHistory: searchHistory ?? this.searchHistory,
      suggestions: suggestions ?? this.suggestions,
      filters: filters ?? this.filters,
      totalResults: totalResults ?? this.totalResults,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }

  bool get isIdle => !isLoading && filters.query.isEmpty && results.isEmpty;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SearchNotifier extends StateNotifier<SearchState> {
  final ApiService _api;
  static const _historyKey = 'hiraya_search_history';
  static const _maxHistory = 10;

  SearchNotifier(this._api) : super(const SearchState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_historyKey) ?? [];

    try {
      final res = await _api.get('/search/trending');
      final trending = (res['trending_products'] as List? ?? [])
          .map((e) => ProductModel.fromJson(e))
          .toList();
      final topics = (res['trending_topics'] as List? ?? [])
          .map((e) => TrendingTopic.fromJson(e))
          .toList();

      state = state.copyWith(
        isLoading: false,
        trendingProducts: trending,
        trendingTopics: topics,
        searchHistory: history,
      );
    } catch (_) {
      // Use dummy data if API unavailable
      state = state.copyWith(
        isLoading: false,
        searchHistory: history,
        trendingProducts: _dummyTrending(),
        trendingTopics: _dummyTopics(),
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
      final res = await _api.get('/search', queryParams: params);
      final newResults = (res['products'] as List? ?? [])
          .map((e) => ProductModel.fromJson(e))
          .toList();

      // Save to history
      if (state.filters.query.isNotEmpty && !loadMore) {
        await _addToHistory(state.filters.query);
      }

      state = state.copyWith(
        isLoading: false,
        results: loadMore ? [...state.results, ...newResults] : newResults,
        totalResults: res['total'] ?? newResults.length,
        currentPage: page,
        hasMore: (res['has_more'] ?? false),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Search failed. Please try again.',
        results: loadMore ? state.results : _dummyResults(state.filters.query),
        totalResults: loadMore ? state.totalResults : 6,
      );
    }
  }

  Future<void> getSuggestions(String query) async {
    if (query.length < 2) {
      state = state.copyWith(suggestions: []);
      return;
    }
    try {
      final res = await _api.get('/search/suggestions', queryParams: {'q': query});
      final suggestions = List<String>.from(res['suggestions'] ?? []);
      state = state.copyWith(suggestions: suggestions);
    } catch (_) {
      // Dummy suggestions
      final dummy = [
        'Solar energy Philippines',
        'Smart irrigation system',
        'Coconut fiber composite',
        'Telemedicine platform',
      ].where((s) => s.toLowerCase().contains(query.toLowerCase())).toList();
      state = state.copyWith(suggestions: dummy);
    }
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters, results: [], currentPage: 1);
    if (filters.query.isNotEmpty || filters.hasActiveFilters) search();
  }

  void setQuery(String q) {
    updateFilters(state.filters.copyWith(query: q));
  }

  void setSortBy(String sort) {
    updateFilters(state.filters.copyWith(sortBy: sort));
  }

  void clearFilters() {
    state = state.copyWith(
      filters: SearchFilters(query: state.filters.query),
      results: [],
    );
    if (state.filters.query.isNotEmpty) search();
  }

  void searchFromHistory(String term) {
    updateFilters(state.filters.copyWith(query: term));
  }

  void searchTrending(String keyword) {
    updateFilters(SearchFilters(query: keyword));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    state = state.copyWith(searchHistory: []);
  }

  Future<void> removeHistoryItem(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(state.searchHistory)..remove(term);
    await prefs.setStringList(_historyKey, history);
    state = state.copyWith(searchHistory: history);
  }

  Future<void> _addToHistory(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final history = List<String>.from(state.searchHistory)
      ..remove(term)
      ..insert(0, term);
    if (history.length > _maxHistory) history.removeLast();
    await prefs.setStringList(_historyKey, history);
    state = state.copyWith(searchHistory: history);
  }

  // ── Dummy data fallback ──────────────────────────────────────────────────

  List<ProductModel> _dummyTrending() => [
        ProductModel(id: 1, title: 'SolarNet Mini Grid', category: 'Energy', price: 45000, innovatorName: 'Miguel Reyes', imageUrl: null, likes: 234, views: 1820, stage: 'mvp', rating: 4.7),
        ProductModel(id: 2, title: 'AquaRice Smart Irrigation', category: 'Agriculture', price: 12000, innovatorName: 'Ana Santos', imageUrl: null, likes: 189, views: 1240, stage: 'market_ready', rating: 4.5),
        ProductModel(id: 3, title: 'CocoComposite Panel', category: 'Construction', price: 8500, innovatorName: 'Rodel Cruz', imageUrl: null, likes: 156, views: 980, stage: 'prototype', rating: 4.2),
        ProductModel(id: 4, title: 'TeleMed Lite', category: 'Healthcare', price: 0, innovatorName: 'Dr. Liza Tan', imageUrl: null, likes: 312, views: 2400, stage: 'market_ready', rating: 4.8),
        ProductModel(id: 5, title: 'GreenBuild AI', category: 'Construction', price: 25000, innovatorName: 'Carlo Mendoza', imageUrl: null, likes: 98, views: 760, stage: 'mvp', rating: 4.1),
        ProductModel(id: 6, title: 'FishTrack IoT', category: 'Agriculture', price: 15000, innovatorName: 'Ben Aquino', imageUrl: null, likes: 143, views: 890, stage: 'prototype', rating: 4.3),
      ];

  List<TrendingTopic> _dummyTopics() => [
        const TrendingTopic(keyword: 'Solar energy', searchCount: 1240, changePercent: 34.2),
        const TrendingTopic(keyword: 'Smart farming', searchCount: 980, changePercent: 21.5),
        const TrendingTopic(keyword: 'Telemedicine', searchCount: 870, changePercent: 18.9),
        const TrendingTopic(keyword: 'IoT sensors', searchCount: 740, changePercent: 12.1),
        const TrendingTopic(keyword: 'Coconut products', searchCount: 620, changePercent: 8.4),
        const TrendingTopic(keyword: 'Water purification', searchCount: 590, changePercent: -3.2),
        const TrendingTopic(keyword: 'Drone delivery', searchCount: 480, changePercent: 45.7),
        const TrendingTopic(keyword: 'Bamboo materials', searchCount: 430, changePercent: 5.1),
      ];

  List<ProductModel> _dummyResults(String q) => _dummyTrending()
      .where((p) => p.title.toLowerCase().contains(q.toLowerCase()) || p.category.toLowerCase().contains(q.toLowerCase()))
      .toList();
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(apiServiceProvider));
});
