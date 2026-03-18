// lib/features/search/screens/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../marketplace/widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _showSuggestions = false;
  late AnimationController _filterAnim;

  @override
  void initState() {
    super.initState();
    _filterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    _focusNode.dispose();
    _filterAnim.dispose();
    super.dispose();
  }

  void _onQueryChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchProvider.notifier).getSuggestions(val);
      if (val.isNotEmpty) {
        ref.read(searchProvider.notifier).setQuery(val);
      }
    });
  }

  void _submitSearch([String? term]) {
    final q = term ?? _queryCtrl.text.trim();
    if (q.isEmpty) return;
    if (term != null) _queryCtrl.text = term;
    _focusNode.unfocus();
    ref.read(searchProvider.notifier).setQuery(q);
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _SearchHeader(
            queryCtrl: _queryCtrl,
            focusNode: _focusNode,
            onChanged: _onQueryChanged,
            onSubmit: _submitSearch,
            onFilterTap: _openFilterSheet,
            activeFilters: state.filters.activeFilterCount,
            state: state,
          ),
          if (_showSuggestions && state.suggestions.isNotEmpty)
            _SuggestionsDropdown(
              suggestions: state.suggestions,
              history: state.searchHistory,
              onTap: (s) {
                _submitSearch(s);
                setState(() => _showSuggestions = false);
              },
            ),
          Expanded(
            child: state.isIdle
                ? _IdleView(state: state, onSearch: _submitSearch)
                : state.isLoading && state.results.isEmpty
                    ? const _LoadingShimmer()
                    : state.results.isEmpty
                        ? _EmptyResults(query: state.filters.query)
                        : _ResultsView(
                            state: state,
                            isWide: isWide,
                            onLoadMore: () =>
                                ref.read(searchProvider.notifier).search(loadMore: true),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Search Header ─────────────────────────────────────────────────────────────

class _SearchHeader extends StatelessWidget {
  final TextEditingController queryCtrl;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;
  final VoidCallback onFilterTap;
  final int activeFilters;
  final SearchState state;

  const _SearchHeader({
    required this.queryCtrl,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onFilterTap,
    required this.activeFilters,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              const Text(
                'Search Innovations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: queryCtrl,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmit(),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.darkGray, fontFamily: 'Poppins'),
                    decoration: InputDecoration(
                      hintText: 'Search innovations, categories, tags...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontFamily: 'Poppins'),
                      prefixIcon:
                          const Icon(Icons.search, color: AppColors.navy, size: 20),
                      suffixIcon: queryCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                queryCtrl.clear();
                                onChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: onFilterTap,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: activeFilters > 0
                            ? AppColors.golden
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: activeFilters > 0 ? AppColors.navy : Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  if (activeFilters > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.crimson,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$activeFilters',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (state.totalResults > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${state.totalResults} result${state.totalResults == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                ),
                const Spacer(),
                _SortChip(current: state.filters.sortBy, onChanged: (_) {}),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SortChip extends ConsumerWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _SortChip({required this.current, required this.onChanged});

  static const _sortLabels = {
    'trending': 'Trending',
    'newest': 'Newest',
    'rating': 'Top Rated',
    'most_liked': 'Most Liked',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showSortMenu(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              _sortLabels[current] ?? 'Sort',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Sort By',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
            ),
            ..._sortLabels.entries.map((e) => ListTile(
                  leading: Icon(
                    current == e.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: current == e.key ? AppColors.crimson : Colors.grey,
                  ),
                  title: Text(
                    e.value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight:
                          current == e.key ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    ref.read(searchProvider.notifier).setSortBy(e.key);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ── Suggestions Dropdown ──────────────────────────────────────────────────────

class _SuggestionsDropdown extends StatelessWidget {
  final List<String> suggestions;
  final List<String> history;
  final ValueChanged<String> onTap;
  const _SuggestionsDropdown(
      {required this.suggestions, required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.take(5).map((s) {
          final isHistory = history.contains(s);
          return ListTile(
            dense: true,
            leading: Icon(
              isHistory ? Icons.history : Icons.search,
              color: Colors.grey,
              size: 18,
            ),
            title: Text(
              s,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.darkGray, fontFamily: 'Poppins'),
            ),
            onTap: () => onTap(s),
          );
        }).toList(),
      ),
    );
  }
}

// ── Idle View ─────────────────────────────────────────────────────────────────

class _IdleView extends ConsumerWidget {
  final SearchState state;
  final ValueChanged<String> onSearch;
  const _IdleView({required this.state, required this.onSearch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.searchHistory.isNotEmpty) ...[
            _SectionHeader(
              title: 'Recent Searches',
              action: 'Clear',
              onAction: () => ref.read(searchProvider.notifier).clearHistory(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.searchHistory
                  .take(8)
                  .map((h) => _HistoryChip(
                        label: h,
                        onTap: () => onSearch(h),
                        onRemove: () => ref
                            .read(searchProvider.notifier)
                            .removeHistoryItem(h),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (state.trendingTopics.isNotEmpty) ...[
            _SectionHeader(title: '🔥 Trending Topics'),
            const SizedBox(height: 12),
            ...state.trendingTopics.take(6).map((t) => _TrendingTopicTile(
                  topic: t,
                  onTap: () => ref
                      .read(searchProvider.notifier)
                      .searchTrending(t.keyword),
                )),
            const SizedBox(height: 24),
          ],
          if (state.trendingProducts.isNotEmpty) ...[
            _SectionHeader(title: '⚡ Popular Innovations'),
            const SizedBox(height: 12),
            SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.trendingProducts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 220,
                  child: ProductCard(
                    product: state.trendingProducts[i],
                    index: i,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                  color: AppColors.crimson, fontSize: 12, fontFamily: 'Poppins'),
            ),
          ),
      ],
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _HistoryChip(
      {required this.label, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lightGray),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 14, color: Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.darkGray, fontFamily: 'Poppins')),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingTopicTile extends StatelessWidget {
  final TrendingTopic topic;
  final VoidCallback onTap;
  const _TrendingTopicTile({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUp = topic.changePercent >= 0;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.navy.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.trending_up, color: AppColors.navy, size: 18),
      ),
      title: Text(
        topic.keyword,
        style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
      ),
      subtitle: Text(
        '${topic.searchCount} searches',
        style: const TextStyle(
            fontSize: 11, color: Colors.grey, fontFamily: 'Poppins'),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isUp
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${isUp ? '+' : ''}${topic.changePercent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: isUp ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── Results View ──────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final SearchState state;
  final bool isWide;
  final VoidCallback onLoadMore;
  const _ResultsView(
      {required this.state, required this.isWide, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (state.filters.hasActiveFilters)
          SliverToBoxAdapter(
            child: _ActiveFilterChips(filters: state.filters),
          ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                if (i == state.results.length) {
                  return state.hasMore
                      ? Center(
                          child: TextButton(
                            onPressed: onLoadMore,
                            child: const Text(
                              'Load more',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        )
                      : const SizedBox();
                }
                return ProductCard(
                  product: state.results[i],
                  index: i,
                );
              },
              childCount: state.results.length + 1,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveFilterChips extends ConsumerWidget {
  final SearchFilters filters;
  const _ActiveFilterChips({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <Widget>[];
    if (filters.category != null)
      chips.add(_Chip(
          label: filters.category!,
          onRemove: () => ref
              .read(searchProvider.notifier)
              .updateFilters(filters.copyWith(clearCategory: true))));
    if (filters.stage != null)
      chips.add(_Chip(
          label: _stageLabel(filters.stage!),
          onRemove: () => ref
              .read(searchProvider.notifier)
              .updateFilters(filters.copyWith(clearStage: true))));
    if (filters.minRating != null)
      chips.add(_Chip(
          label: '${filters.minRating}★+',
          onRemove: () => ref
              .read(searchProvider.notifier)
              .updateFilters(filters.copyWith(clearMinRating: true))));
    if (filters.sortBy != 'trending')
      chips.add(_Chip(
          label: 'Sort: ${filters.sortBy}',
          onRemove: () =>
              ref.read(searchProvider.notifier).setSortBy('trending')));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...chips,
          TextButton(
            onPressed: () => ref.read(searchProvider.notifier).clearFilters(),
            child: const Text(
              'Clear all',
              style: TextStyle(
                  color: AppColors.crimson, fontSize: 12, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  String _stageLabel(String s) {
    const m = {
      'concept': 'Concept',
      'prototype': 'Prototype',
      'mvp': 'MVP',
      'market_ready': 'Market Ready',
    };
    return m[s] ?? s;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ── Loading Shimmer ───────────────────────────────────────────────────────────

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(height: 10, color: Colors.grey.shade300),
                    const SizedBox(height: 4),
                    Container(height: 8, width: 80, color: Colors.grey.shade300),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Results ─────────────────────────────────────────────────────────────

class _EmptyResults extends StatelessWidget {
  final String query;
  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or adjust filters',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _FilterSheet({required this.ref});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late SearchFilters _local;
  RangeValues _priceRange = const RangeValues(0, 500000);
  double _minRating = 0;

  static const _categories = [
    'Agriculture', 'Healthcare', 'Energy',
    'Construction', 'Product Design', 'Information Technology'
  ];
  static const _stages = [
    ('concept', 'Concept'),
    ('prototype', 'Prototype'),
    ('mvp', 'MVP'),
    ('market_ready', 'Market Ready'),
  ];

  @override
  void initState() {
    super.initState();
    _local = ref.read(searchProvider).filters;
    _priceRange = RangeValues(_local.minPrice ?? 0, _local.maxPrice ?? 500000);
    _minRating = _local.minRating ?? 0;
  }

  void _apply() {
    final updated = _local.copyWith(
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 500000 ? _priceRange.end : null,
      minRating: _minRating > 0 ? _minRating : null,
    );
    ref.read(searchProvider.notifier).updateFilters(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _local = const SearchFilters(query: '');
                        _priceRange = const RangeValues(0, 500000);
                        _minRating = 0;
                      });
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                          color: AppColors.crimson, fontFamily: 'Poppins'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterSection(
                    title: 'Category',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map((c) => _SelectableChip(
                                label: c,
                                selected: _local.category == c,
                                onTap: () => setState(() {
                                  _local = _local.copyWith(
                                    category: _local.category == c ? null : c,
                                    clearCategory: _local.category == c,
                                  );
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title: 'Innovation Stage',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stages
                          .map((s) => _SelectableChip(
                                label: s.$2,
                                selected: _local.stage == s.$1,
                                onTap: () => setState(() {
                                  _local = _local.copyWith(
                                    stage: _local.stage == s.$1 ? null : s.$1,
                                    clearStage: _local.stage == s.$1,
                                  );
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title:
                        'Price Range (₱${_priceRange.start.toInt()} – ${_priceRange.end >= 500000 ? 'Any' : '₱${_priceRange.end.toInt()}'})',
                    child: RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 500000,
                      divisions: 50,
                      activeColor: AppColors.navy,
                      inactiveColor: AppColors.lightGray,
                      onChanged: (v) => setState(() => _priceRange = v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title:
                        'Minimum Rating${_minRating > 0 ? ': ${_minRating.toStringAsFixed(1)}★' : ''}',
                    child: Slider(
                      value: _minRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _minRating > 0
                          ? '${_minRating.toStringAsFixed(1)}★'
                          : 'Any',
                      activeColor: AppColors.golden,
                      inactiveColor: AppColors.lightGray,
                      onChanged: (v) => setState(() => _minRating = v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FilterSection(
                    title: 'Additional Filters',
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text(
                            'Verified Innovators Only',
                            style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                          ),
                          value: _local.showOnlyVerified,
                          onChanged: (v) => setState(
                              () => _local = _local.copyWith(showOnlyVerified: v)),
                          activeColor: AppColors.navy,
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          title: const Text(
                            'Available for Investment',
                            style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                          ),
                          value: _local.showOnlyAvailable,
                          onChanged: (v) => setState(
                              () => _local = _local.copyWith(showOnlyAvailable: v)),
                          activeColor: AppColors.navy,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectableChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.navy : AppColors.lightGray),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : AppColors.darkGray,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}