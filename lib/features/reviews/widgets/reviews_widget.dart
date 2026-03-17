// lib/features/reviews/widgets/reviews_widget.dart
// ignore_for_file: library_private_types_in_public_api
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/review_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class ReviewsSection extends ConsumerWidget {
  final int productId;
  const ReviewsSection({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state    = ref.watch(reviewProvider(productId));
    final auth     = ref.watch(authProvider);
    final isClient = auth.isLoggedIn && auth.user?.role == 'client';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(0, 24, 0, 16),
          child: Text(
            'Ratings & Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        if (state.stats != null) _RatingStats(stats: state.stats!),
        const SizedBox(height: 16),
        if (!auth.isLoggedIn)
          _SignInToReviewNudge()
        else if (!isClient)
          const SizedBox.shrink()   // innovators/admins see nothing
        else if (state.userReview == null)
          _WriteReviewCard(productId: productId)
        else
          _UserReviewCard(review: state.userReview!, productId: productId),
        const SizedBox(height: 16),
        if (state.reviews.isNotEmpty)
          Row(
            children: [
              const Text('Sort: ',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey, fontFamily: 'Poppins')),
              ...[('recent', 'Recent'), ('helpful', 'Helpful'), ('rating', 'Rating')]
                  .map((s) => GestureDetector(
                        onTap: () =>
                            ref.read(reviewProvider(productId).notifier).setSort(s.$1),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: state.sort == s.$1 ? AppColors.navy : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.lightGray),
                          ),
                          child: Text(
                            s.$2,
                            style: TextStyle(
                              fontSize: 12,
                              color: state.sort == s.$1
                                  ? Colors.white
                                  : AppColors.darkGray,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      )),
            ],
          ),
        const SizedBox(height: 12),
        if (state.isLoading && state.reviews.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          ...state.reviews
              .map((r) => _ReviewCard(review: r, productId: productId)),
        if (state.hasMore)
          Center(
            child: TextButton(
              onPressed: () =>
                  ref.read(reviewProvider(productId).notifier).load(loadMore: true),
              child: const Text(
                'Load more reviews',
                style: TextStyle(color: AppColors.navy, fontFamily: 'Poppins'),
              ),
            ),
          ),
        if (state.reviews.isEmpty && !state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No reviews yet. Be the first!',
                style: TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Rating Stats Summary ──────────────────────────────────────────────────────

class _RatingStats extends StatelessWidget {
  final ReviewStats stats;
  const _RatingStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                stats.avgRating?.toStringAsFixed(1) ?? '—',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  fontFamily: 'Poppins',
                ),
              ),
              _StarRow(rating: stats.avgRating?.round() ?? 0, size: 16),
              const SizedBox(height: 4),
              Text(
                '${stats.total} review${stats.total == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = stats.breakdown[star] ?? 0;
                final pct = stats.total > 0 ? count / stats.total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'Poppins')),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: AppColors.golden),
                      const SizedBox(width: 6),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.lightGray,
                          color: AppColors.golden,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontFamily: 'Poppins')),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sign-in nudge ─────────────────────────────────────────────────────────────

class _SignInToReviewNudge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        const Icon(Icons.rate_review_outlined, color: AppColors.navy, size: 20),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Sign in as a Client to leave a review.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.navy),
          ),
        ),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Sign In',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  fontWeight: FontWeight.w600, color: AppColors.crimson)),
        ),
      ]),
    );
  }
}

// ── Write a Review ────────────────────────────────────────────────────────────

class _WriteReviewCard extends ConsumerStatefulWidget {
  final int productId;
  const _WriteReviewCard({required this.productId});

  @override
  ConsumerState<_WriteReviewCard> createState() => _WriteReviewCardState();
}

class _WriteReviewCardState extends ConsumerState<_WriteReviewCard> {
  int _rating = 0;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }
    if (_bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please write a review')));
      return;
    }
    final ok = await ref
        .read(reviewProvider(widget.productId).notifier)
        .submitReview(
          rating: _rating,
          title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted!')));
      setState(() {
        _expanded = false;
        _rating = 0;
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting =
        ref.watch(reviewProvider(widget.productId)).isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rate_review_outlined,
                  color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Write a Review',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              if (!_expanded)
                TextButton(
                  onPressed: () => setState(() => _expanded = true),
                  child: const Text(
                    'Write',
                    style: TextStyle(
                        color: AppColors.crimson,
                        fontSize: 13,
                        fontFamily: 'Poppins'),
                  ),
                ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star),
                  child: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.golden,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              decoration: _inputDecoration('Title (optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              decoration: _inputDecoration(
                  'Share your experience with this innovation...'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _expanded = false),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.lightGray)),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy),
        ),
      );
}

// ── User's own review ─────────────────────────────────────────────────────────

class _UserReviewCard extends ConsumerStatefulWidget {
  final Review review;
  final int productId;
  const _UserReviewCard({required this.review, required this.productId});

  @override
  ConsumerState<_UserReviewCard> createState() => _UserReviewCardState();
}

class _UserReviewCardState extends ConsumerState<_UserReviewCard> {
  bool _editing = false;
  late int _rating;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _rating   = widget.review.rating;
    _titleCtrl = TextEditingController(text: widget.review.title ?? '');
    _bodyCtrl  = TextEditingController(text: widget.review.body);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating == 0 || _bodyCtrl.text.trim().isEmpty) return;
    final ok = await ref.read(reviewProvider(widget.productId).notifier).updateReview(
      reviewId: widget.review.id,
      rating:   _rating,
      title:    _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      body:     _bodyCtrl.text.trim(),
    );
    if (ok && mounted) setState(() => _editing = false);
  }

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightGray)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.lightGray)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.navy)),
  );

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(reviewProvider(widget.productId)).isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (!_editing) _StarRow(rating: widget.review.rating, size: 16),
          const Spacer(),
          const Text('Your Review',
              style: TextStyle(fontSize: 12, color: AppColors.navy,
                  fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          IconButton(
            icon: Icon(_editing ? Icons.close_rounded : Icons.edit_outlined,
                color: AppColors.navy, size: 18),
            tooltip: _editing ? 'Cancel edit' : 'Edit review',
            onPressed: () => setState(() {
              if (_editing) {
                // reset
                _rating = widget.review.rating;
                _titleCtrl.text = widget.review.title ?? '';
                _bodyCtrl.text  = widget.review.body;
              }
              _editing = !_editing;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
            tooltip: 'Delete review',
            onPressed: () => ref.read(reviewProvider(widget.productId).notifier)
                .deleteReview(widget.review.id),
          ),
        ]),

        if (_editing) ...[
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) {
            final star = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _rating = star),
              child: Icon(
                star <= _rating ? Icons.star : Icons.star_border,
                color: AppColors.golden, size: 28,
              ),
            );
          })),
          const SizedBox(height: 10),
          TextField(controller: _titleCtrl,
              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              decoration: _dec('Title (optional)')),
          const SizedBox(height: 8),
          TextField(controller: _bodyCtrl, maxLines: 3,
              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              decoration: _dec('Update your review...')),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                          fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ] else ...[
          if (widget.review.title != null)
            Text(widget.review.title!,
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
          Text(widget.review.body,
              style: TextStyle(fontSize: 13,
                  color: Colors.grey.shade700, fontFamily: 'Poppins')),
        ],
      ]),
    );
  }
}

// ── Single Review Card ────────────────────────────────────────────────────────

class _ReviewCard extends ConsumerWidget {
  final Review review;
  final int productId;
  const _ReviewCard({required this.review, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.navy,
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                  ),
                  Text(
                    DateFormat('MMM d, y').format(review.createdAt),
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
              const Spacer(),
              _StarRow(rating: review.rating, size: 14),
            ],
          ),
          if (review.title != null) ...[
            const SizedBox(height: 8),
            Text(
              review.title!,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkGray,
                  fontFamily: 'Poppins'),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            review.body,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => ref
                .read(reviewProvider(productId).notifier)
                .markHelpful(review.id),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  review.markedHelpful
                      ? Icons.thumb_up
                      : Icons.thumb_up_outlined,
                  size: 15,
                  color: review.markedHelpful ? AppColors.navy : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Helpful (${review.helpfulCount})',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        review.markedHelpful ? AppColors.navy : Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Star Row ──────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: AppColors.golden,
          size: size,
        );
      }),
    );
  }
}