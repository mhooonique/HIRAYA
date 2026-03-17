// lib/features/reviews/providers/review_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class Review {
  final int id;
  final int productId;
  final int userId;
  final int rating;
  final String? title;
  final String body;
  final int helpfulCount;
  final bool markedHelpful;
  final String reviewerName;
  final String reviewerUsername;
  final String reviewerRole;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.title,
    required this.body,
    required this.helpfulCount,
    required this.markedHelpful,
    required this.reviewerName,
    required this.reviewerUsername,
    required this.reviewerRole,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'],
        productId: j['product_id'],
        userId: j['user_id'],
        rating: j['rating'],
        title: j['title'],
        body: j['body'] ?? '',
        helpfulCount: j['helpful_count'] ?? 0,
        markedHelpful: j['marked_helpful'] ?? false,
        reviewerName: j['reviewer_name'] ?? 'Anonymous',
        reviewerUsername: j['reviewer_username'] ?? '',
        reviewerRole: j['reviewer_role'] ?? 'client',
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      );
}

class ReviewStats {
  final int total;
  final double? avgRating;
  final Map<int, int> breakdown;

  const ReviewStats({
    required this.total,
    required this.avgRating,
    required this.breakdown,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> j) {
    final raw = j['breakdown'] as Map<String, dynamic>? ?? {};
    return ReviewStats(
      total: j['total'] ?? 0,
      avgRating: j['avg_rating'] != null ? (j['avg_rating'] as num).toDouble() : null,
      breakdown: {
        5: raw['5'] ?? 0,
        4: raw['4'] ?? 0,
        3: raw['3'] ?? 0,
        2: raw['2'] ?? 0,
        1: raw['1'] ?? 0,
      },
    );
  }
}

class ReviewState {
  final bool isLoading;
  final List<Review> reviews;
  final ReviewStats? stats;
  final Review? userReview;
  final bool hasMore;
  final int page;
  final String sort;
  final String? error;
  final bool isSubmitting;

  const ReviewState({
    this.isLoading = false,
    this.reviews = const [],
    this.stats,
    this.userReview,
    this.hasMore = false,
    this.page = 1,
    this.sort = 'recent',
    this.error,
    this.isSubmitting = false,
  });

  ReviewState copyWith({
    bool? isLoading,
    List<Review>? reviews,
    ReviewStats? stats,
    Review? userReview,
    bool? hasMore,
    int? page,
    String? sort,
    String? error,
    bool? isSubmitting,
    bool clearUserReview = false,
  }) =>
      ReviewState(
        isLoading: isLoading ?? this.isLoading,
        reviews: reviews ?? this.reviews,
        stats: stats ?? this.stats,
        userReview: clearUserReview ? null : (userReview ?? this.userReview),
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        sort: sort ?? this.sort,
        error: error,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ReviewNotifier extends StateNotifier<ReviewState> {
  final ApiService _api;
  final int _productId;

  ReviewNotifier(this._api, this._productId) : super(const ReviewState()) {
    load();
  }

  Future<void> load({bool loadMore = false}) async {
    final page = loadMore ? state.page + 1 : 1;
    if (!loadMore) state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _api.get('/reviews', queryParams: {
        'product_id': _productId.toString(),
        'page': page.toString(),
        'sort': state.sort,
      });
      final newReviews = (res['reviews'] as List? ?? [])
          .map((e) => Review.fromJson(e))
          .toList();
      final stats =
          res['stats'] != null ? ReviewStats.fromJson(res['stats']) : null;
      final ur =
          res['user_review'] != null ? Review.fromJson(res['user_review']) : null;

      state = state.copyWith(
        isLoading: false,
        reviews: loadMore ? [...state.reviews, ...newReviews] : newReviews,
        stats: stats,
        userReview: ur,
        hasMore: res['has_more'] ?? false,
        page: page,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load reviews');
    }
  }

  Future<bool> submitReview({
    required int rating,
    required String body,
    String? title,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _api.post('/reviews', {
        'product_id': _productId,
        'rating': rating,
        'title': title,
        'body': body,
      });
      await load();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'Failed to submit review');
      return false;
    }
  }

  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String body,
    String? title,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      await _api.put('/reviews/$reviewId', {
        'rating': rating,
        'title': title,
        'body': body,
      });
      await load();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: 'Failed to update review');
      return false;
    }
  }

  Future<void> deleteReview(int reviewId) async {
    try {
      await _api.delete('/reviews/$reviewId');
      await load();
    } catch (_) {}
  }

  Future<void> markHelpful(int reviewId) async {
    try {
      final res = await _api.post('/reviews/$reviewId/helpful', {});
      final isHelpful = res['helpful'] as bool? ?? false;
      final updated = state.reviews.map((r) {
        if (r.id != reviewId) return r;
        return Review(
          id: r.id,
          productId: r.productId,
          userId: r.userId,
          rating: r.rating,
          title: r.title,
          body: r.body,
          helpfulCount: isHelpful ? r.helpfulCount + 1 : r.helpfulCount - 1,
          markedHelpful: isHelpful,
          reviewerName: r.reviewerName,
          reviewerUsername: r.reviewerUsername,
          reviewerRole: r.reviewerRole,
          createdAt: r.createdAt,
        );
      }).toList();
      state = state.copyWith(reviews: updated);
    } catch (_) {}
  }

  void setSort(String sort) {
    state = state.copyWith(sort: sort, reviews: [], page: 1);
    load();
  }
}

final reviewProvider =
    StateNotifierProviderFamily<ReviewNotifier, ReviewState, int>(
  (ref, productId) => ReviewNotifier(ref.read(apiServiceProvider), productId),
);