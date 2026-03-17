// lib/features/profile/screens/public_profile_screen.dart

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';

// Suppress unused import warning for dart:html — used in _VideoCard via html.window
// ignore_for_file: unused_import

// ── State ─────────────────────────────────────────────────────────────────────
class _ProfileData {
  final Map<String, dynamic> user;
  final List<ProductModel> products;
  const _ProfileData({required this.user, required this.products});
}

// ── Provider ──────────────────────────────────────────────────────────────────
final _publicProfileProvider =
    FutureProvider.family<_ProfileData, int>((ref, userId) async {
  final api = ref.read(apiServiceProvider);
  final res = await api.get('users/$userId/profile');
  if (res['success'] != true) throw Exception('User not found');
  final userData = res['data'] as Map<String, dynamic>;
  final productsJson =
      (userData['products'] as List<dynamic>?) ?? [];
  final products = productsJson
      .map((j) => ProductModel.fromJson(j as Map<String, dynamic>))
      .toList();
  return _ProfileData(user: userData, products: products);
});

// ── Screen ────────────────────────────────────────────────────────────────────
class PublicProfileScreen extends ConsumerWidget {
  final int userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_publicProfileProvider(userId));
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: profileAsync.when(
        loading: () => const _LoadingView(),
        error: (e, _) => _ErrorView(onBack: () => context.pop()),
        data: (profile) => _ProfileView(
          profile: profile,
          isLoggedIn: isLoggedIn,
          onBack: () => context.pop(),
          onMessage: () =>
              context.go(isLoggedIn ? '/messaging' : '/login'),
          onProductTap: (id) => context.go('/product/$id'),
        ),
      ),
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.teal)),
      );
}

// ── Error View ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final VoidCallback onBack;
  const _ErrorView({required this.onBack});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_rounded,
                size: 64, color: AppColors.lightGray),
            const SizedBox(height: 16),
            const Text('Profile not found',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: onBack,
                child: const Text('Go back')),
          ]),
        ),
      );
}

// ── Profile View ──────────────────────────────────────────────────────────────
class _ProfileView extends StatelessWidget {
  final _ProfileData profile;
  final bool isLoggedIn;
  final VoidCallback onBack;
  final VoidCallback onMessage;
  final void Function(int) onProductTap;

  const _ProfileView({
    required this.profile,
    required this.isLoggedIn,
    required this.onBack,
    required this.onMessage,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final u = profile.user;
    final firstName = (u['first_name'] as String? ?? 'U');
    final lastName = (u['last_name'] as String? ?? '');
    final fullName = '$firstName $lastName'.trim();
    final username = u['username'] as String? ?? '';
    final kycStatus = u['kyc_status'] as String? ?? 'unverified';
    final socialLinks =
        (u['social_links'] as Map<String, dynamic>?) ?? {};
    final products = profile.products;

    // Pick a color based on first letter
    const colors = [
      AppColors.teal,
      AppColors.sky,
      AppColors.navy,
      AppColors.golden,
      AppColors.crimson
    ];
    final profileColor =
        colors[firstName.codeUnitAt(0) % colors.length];

    return CustomScrollView(
      slivers: [
        // ── Hero App Bar ─────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: profileColor,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 18),
            ),
            onPressed: onBack,
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    profileColor,
                    profileColor.withValues(alpha: 0.7)
                  ],
                ),
              ),
              child: Stack(children: [
                // Background circle decorations
                Positioned(
                    right: -60,
                    top: -60,
                    child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: 0.06),
                        ))),
                Positioned(
                    left: -40,
                    bottom: -40,
                    child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: 0.04),
                        ))),
                // Profile content
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withValues(alpha: 0.2),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.4),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            firstName
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                      ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut),
                      const SizedBox(height: 12),
                      // Name
                      Text(fullName,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1))
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 4),
                      Row(children: [
                        Text('@$username',
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Colors.white70))
                            .animate()
                            .fadeIn(delay: 150.ms),
                        const SizedBox(width: 10),
                        if (kycStatus == 'verified')
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                    Icons.verified_rounded,
                                    color: Colors.white,
                                    size: 11),
                                SizedBox(width: 4),
                                Text('Verified',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),
                      ]),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.message_rounded,
                        size: 18, color: Colors.white),
                    label: const Text('Send Message',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: profileColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14)),
                      elevation: 4,
                      shadowColor:
                          profileColor.withValues(alpha: 0.4),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(
                    begin: 0.2, end: 0),

                // Social links
                if (socialLinks.values.any((v) =>
                    v != null &&
                    v.toString().isNotEmpty)) ...[
                  const SizedBox(height: 20),
                  _SocialLinksRow(links: socialLinks),
                ],

                const SizedBox(height: 24),

                // Innovations header
                Row(children: [
                  const Text('Innovations',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: profileColor
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(8)),
                    child: Text('${products.length}',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: profileColor)),
                  ),
                ]).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),

                // Products list
                if (products.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.lightGray)),
                    child: const Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                Icons
                                    .lightbulb_outline_rounded,
                                size: 48,
                                color: AppColors.lightGray),
                            SizedBox(height: 12),
                            Text('No innovations yet',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.w700,
                                    color: AppColors.navy)),
                          ]),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) =>
                        _ProfileProductCard(
                      product: products[i],
                      index: i,
                      onTap: () =>
                          onProductTap(products[i].id),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Social Links Row ──────────────────────────────────────────────────────────
class _SocialLinksRow extends StatelessWidget {
  final Map<String, dynamic> links;
  const _SocialLinksRow({required this.links});

  static const _icons = {
    'facebook': Icons.facebook_rounded,
    'instagram': Icons.camera_alt_rounded,
    'linkedin': Icons.work_rounded,
    'x': Icons.close_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray)),
      child: Row(
        children: [
          const Text('Connect',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy)),
          const SizedBox(width: 16),
          ..._icons.entries
              .where((e) =>
                  links[e.key] != null &&
                  links[e.key].toString().isNotEmpty)
              .map((e) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => launchUrl(
                          Uri.parse(links[e.key].toString()),
                          mode:
                              LaunchMode.externalApplication),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: AppColors.offWhite,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.lightGray)),
                        child: Icon(e.value,
                            size: 20, color: AppColors.navy),
                      ),
                    ),
                  )),
        ],
      ),
    ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1, end: 0);
  }
}

// ── Profile Product Card ──────────────────────────────────────────────────────
class _ProfileProductCard extends StatefulWidget {
  final ProductModel product;
  final int index;
  final VoidCallback onTap;
  const _ProfileProductCard(
      {required this.product,
      required this.index,
      required this.onTap});
  @override
  State<_ProfileProductCard> createState() =>
      _ProfileProductCardState();
}

class _ProfileProductCardState
    extends State<_ProfileProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final catColor =
        AppColors.categoryColors[widget.product.category] ??
            AppColors.navy;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _hovered
                    ? catColor.withValues(alpha: 0.3)
                    : AppColors.lightGray),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? catColor.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _hovered ? 16 : 6,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(children: [
            // Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: widget.product.images.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: (() {
                        try {
                          return Image.memory(
                              base64Decode(widget
                                  .product.images.first),
                              fit: BoxFit.cover);
                        } catch (_) {
                          return Icon(
                              Icons.lightbulb_rounded,
                              color: catColor,
                              size: 28);
                        }
                      })(),
                    )
                  : Icon(Icons.lightbulb_rounded,
                      color: catColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.product.name,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(widget.product.description,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black45),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.favorite_rounded,
                        size: 11, color: AppColors.crimson),
                    const SizedBox(width: 3),
                    Text('${widget.product.likes}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.black45)),
                    const SizedBox(width: 10),
                    Icon(Icons.remove_red_eye_rounded,
                        size: 11, color: Colors.black38),
                    const SizedBox(width: 3),
                    Text('${widget.product.views}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.black45)),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: _hovered ? catColor : Colors.black26),
          ]),
        ),
      ),
    )
        .animate(
            delay: Duration(
                milliseconds: 60 * widget.index))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.15, end: 0);
  }
}
