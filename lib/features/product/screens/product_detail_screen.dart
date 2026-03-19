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
import '../../marketplace/providers/marketplace_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/share_qr_section.dart';
import '../../reviews/widgets/reviews_widget.dart';


final _productDetailProvider =
    FutureProvider.family<ProductModel?, int>((ref, id) async {
  final api = ref.read(apiServiceProvider);
  try {
    final res = await api.get('products/$id', auth: true);
    if (res['success'] == true) {
      return ProductModel.fromJson(res['data'] as Map<String, dynamic>);
    }
  } catch (_) {}
  return ref
      .read(marketplaceProvider)
      .products
      .cast<ProductModel?>()
      .firstWhere((p) => p?.id == id, orElse: () => null);
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _liked = false;
  bool _bookmarked = false;
  bool _interestSent = false;

  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String category) =>
      AppColors.categoryColors[category] ?? AppColors.teal;

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Agriculture':            return Icons.grass_rounded;
      case 'Healthcare':             return Icons.medical_services_rounded;
      case 'Energy':                 return Icons.bolt_rounded;
      case 'Construction':           return Icons.foundation_rounded;
      case 'Product Design':         return Icons.design_services_rounded;
      case 'Information Technology': return Icons.computer_rounded;
      default:                       return Icons.lightbulb_rounded;
    }
  }

  void _openImageViewer(BuildContext context, List<String> images, int initialPage) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.90),
      builder: (_) =>
          _ImageViewer(images: images, initialPage: initialPage),
    );
  }

  void _goBack(BuildContext context, String role) {
    if (role == 'admin') {
      context.go('/admin');
    } else if (role == 'innovator') {
      context.go('/innovator/dashboard');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/marketplace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(_productDetailProvider(widget.productId));
    final product = productAsync.value;
<<<<<<< HEAD
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isLoggedIn;
    final isAdmin = authState.user?.role == 'admin';

=======

    final isDark        = ref.watch(themeProvider) == ThemeMode.dark;
    final scaffoldBg    = isDark ? const Color(0xFF0D1117) : AppColors.offWhite;
    final cardBg        = isDark ? const Color(0xFF1A2233) : Colors.white;
    final borderCol     = isDark ? const Color(0xFF2A3448) : AppColors.lightGray;
    final primaryText   = isDark ? Colors.white : AppColors.navy;
    final secondaryText = isDark ? Colors.white54 : Colors.black54;
    final subtleText    = isDark ? Colors.white38 : Colors.black45;

    final authState   = ref.watch(authProvider);
    final isLoggedIn  = authState.isLoggedIn;
    final role        = authState.user?.role ?? '';
    final isAdmin     = role == 'admin';
    final isInnovator = role == 'innovator';
    final isClient    = isLoggedIn && role == 'client';
    // Restricted = admin/innovator → no like/interest/message/bookmark
    final isRestricted = isAdmin || isInnovator;
>>>>>>> origin/master

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.deepVoid,
        appBar: AppBar(
          backgroundColor: AppColors.midnight,
          elevation: 0,
          leading: _BackButton(onTap: () => context.go('/marketplace')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  color: AppColors.golden,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading innovation...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = _categoryColor(product.category);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: CustomScrollView(
        slivers: [
<<<<<<< HEAD
          // ── Cinematic SliverAppBar hero ──────────────────
=======
          // ── Hero AppBar ───────────────────────────────────────────────────
>>>>>>> origin/master
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: AppColors.midnight,
            elevation: 0,
            leading: _BackButton(onTap: () => context.go('/marketplace')),
            actions: [
              // Admin dashboard button
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
<<<<<<< HEAD
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${product.images.length}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
=======
                    child: GestureDetector(
                      onTap: () => context.go('/admin'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Admin Dashboard', style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]),
>>>>>>> origin/master
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
              // Bookmark
              Container(
                margin: const EdgeInsets.only(right: 4),
                child: IconButton(
=======
              // Innovator dashboard button
              if (isInnovator)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => context.go('/innovator/dashboard'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.dashboard_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('My Dashboard', style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
              // Image count — clients/guests only
              if (!isRestricted && product.images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.black45,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.photo_library_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text('${product.images.length}',
                            style: const TextStyle(fontFamily: 'Poppins',
                                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              // Bookmark — clients only
              if (isClient)
                IconButton(
>>>>>>> origin/master
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _bookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      key: ValueKey(_bookmarked),
                      color: _bookmarked
                          ? AppColors.golden
                          : Colors.white70,
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _bookmarked = !_bookmarked),
                ),
<<<<<<< HEAD
=======
              // Share — everyone
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () async {
                  final url = '${html.window.location.origin}/product/${product.id}';
                  await html.window.navigator.clipboard?.writeText(url);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Product link copied!',
                        style: TextStyle(fontFamily: 'Poppins')),
                    backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                },
>>>>>>> origin/master
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: Colors.white70),
                onPressed: () {},
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.images.isNotEmpty
                  ? _buildImageGallery(product, color)
                  : _buildGradientFallback(product, color),
            ),
          ),

<<<<<<< HEAD
          // ── Body content ─────────────────────────────────
=======
          // ── Body ─────────────────────────────────────────────────────────
>>>>>>> origin/master
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Status banner
                  if (product.status != 'approved')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: product.status == 'pending'
                            ? AppColors.golden.withValues(alpha: 0.1)
                            : AppColors.crimson.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: product.status == 'pending'
                              ? AppColors.golden.withValues(alpha: 0.4)
                              : AppColors.crimson.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          product.status == 'pending'
                              ? Icons.pending_rounded : Icons.cancel_rounded,
                          color: product.status == 'pending'
                              ? AppColors.golden : AppColors.crimson,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          product.status == 'pending'
                              ? 'This post is pending admin review'
                              : 'This post was rejected by admin',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: product.status == 'pending'
                                  ? AppColors.golden : AppColors.crimson),
                        ),
                      ]),
                    ).animate().fadeIn(),

                  // Innovator card
                  GestureDetector(
<<<<<<< HEAD
                    onTap: () =>
                        context.go('/profile/${product.innovatorId}'),
                    child: _GlassCard(
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  color.withValues(alpha: 0.20),
                              child: Text(
                                product.innovatorName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
=======
                    onTap: () => context.push('/profile/${product.innovatorId}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Row(children: [
                        UserAvatar(
                          name: product.innovatorName,
                          avatarBase64: product.innovatorAvatarBase64,
                          radius: 24,
                          backgroundColor: color.withValues(alpha: 0.15),
                          foregroundColor: color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.innovatorName, style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 15, fontWeight: FontWeight.w700, color: primaryText)),
                            Text('@${product.innovatorUsername}', style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13, color: subtleText)),
                          ],
                        )),
                        // Admin/Innovator → View Profile
                        // Client → Message
                        // Guest → Message (redirects to login)
                        if (isRestricted)
                          OutlinedButton.icon(
                            onPressed: () => context.push('/profile/${product.innovatorId}'),
                            icon: const Icon(Icons.person_search_rounded, size: 16),
                            label: const Text('View Profile', style: TextStyle(
                                fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.sky,
                              side: const BorderSide(color: AppColors.sky),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => context.push(isLoggedIn ? '/messaging' : '/login'),
                            icon: const Icon(Icons.message_rounded, size: 16),
                            label: const Text('Message', style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 13, fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: color, side: BorderSide(color: color),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
>>>>>>> origin/master
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.innovatorName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '@${product.innovatorUsername}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.white
                                        .withValues(alpha: 0.38),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Message button — teal outlined
                          _OutlineActionButton(
                            label: 'Message',
                            icon: Icons.message_rounded,
                            color: AppColors.teal,
                            onTap: () => context.go(
                                isLoggedIn ? '/messaging' : '/login'),
                          ),
                      ]),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

<<<<<<< HEAD
                  // Video section
                  if (product.videoBase64 != null &&
                      product.videoBase64!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Video'),
                    const SizedBox(height: 14),
                    _VideoCard(
                      videoBase64: product.videoBase64!,
                      filename:
                          product.videoFilename ?? 'video.mp4',
                    ),
                  ],

                  const SizedBox(height: 28),

                  // About section
                  const _SectionHeader(
                      title: 'About this Innovation'),
                  const SizedBox(height: 14),
                  _GlassCard(
                    child: Text(
                      product.description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.65),
                        height: 1.75,
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 28),

                  // Details grid
                  const _SectionHeader(title: 'Details'),
                  const SizedBox(height: 14),
=======
                  // Guest sign-in banner
                  if (!isLoggedIn) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sky.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sky.withValues(alpha: 0.4)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.sky, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(TextSpan(
                              style: const TextStyle(fontFamily: 'Poppins',
                                  fontSize: 12, color: AppColors.sky),
                              children: const [
                                TextSpan(text: 'Join as a CLIENT '),
                                TextSpan(text: 'to like, message, bookmark, and express interest.',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            )),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.sky, size: 14),
                        ]),
                      ),
                    ).animate().fadeIn(),
                  ],

                  // ── Big Gallery ───────────────────────────────────────────
                  if (product.images.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLabel('Gallery', Icons.photo_library_rounded, primaryText),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 600,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemCount: product.images.length,
                          itemBuilder: (_, i) {
                            try {
                              return GestureDetector(
                                onTap: () => _openImageViewer(context, product.images, i),
                                child: Image.memory(
                                  base64Decode(product.images[i]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            } catch (_) {
                              return Container(
                                color: color.withValues(alpha: 0.1),
                                child: Icon(Icons.image_rounded, color: color, size: 48),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(product.images.length,
                        (i) => AnimatedContainer(
                          duration: 200.ms,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 20 : 6, height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i ? color : color.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text('Tap image to view fullscreen',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.black38)),
                    ),
                  ],

                  // Video
                  if (product.videoBase64 != null && product.videoBase64!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLabel('Video', Icons.videocam_rounded, primaryText),
                    const SizedBox(height: 12),
                    _VideoCard(videoBase64: product.videoBase64!,
                        filename: product.videoFilename ?? 'video.mp4'),
                  ],

                  const SizedBox(height: 24),
                  _buildLabel('About this Innovation', Icons.lightbulb_rounded, primaryText),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol)),
                    child: Text(product.description, style: TextStyle(fontFamily: 'Poppins',
                        fontSize: 14, color: secondaryText, height: 1.7)),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 24),
                  _buildLabel('Details', Icons.info_outline_rounded, primaryText),
                  const SizedBox(height: 12),
>>>>>>> origin/master
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _DetailChip(
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: product.category,
                        color: color,
                      ),
                      _DetailChip(
                        icon: Icons.verified_user_rounded,
                        label: 'KYC Status',
                        value: product.kycStatus.toUpperCase(),
                        color: product.isVerifiedInnovator
                            ? AppColors.teal
                            : AppColors.golden,
                      ),
                      _DetailChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Listed',
                        value:
                            '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                        color: AppColors.sky,
                      ),
                      _DetailChip(
                        icon: Icons.bar_chart_rounded,
                        label: 'Status',
                        value: product.status.toUpperCase(),
                        color: AppColors.teal,
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

<<<<<<< HEAD
                  // External link section
                  if (product.externalLink != null &&
                      product.externalLink!.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'External Link'),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(product.externalLink!),
                          mode: LaunchMode.externalApplication),
                      child: _GlassCard(
=======
                  if (product.externalLink != null && product.externalLink!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLabel('External Link', Icons.link_rounded, primaryText),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(product.externalLink!),
                          mode: LaunchMode.externalApplication),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderCol),
                        ),
>>>>>>> origin/master
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.sky
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.sky
                                    .withValues(alpha: 0.20),
                              ),
                            ),
                            child: const Icon(Icons.link_rounded,
                                color: AppColors.sky, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('Learn More',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    )),
                                Text(
                                  product.externalLink!,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: AppColors.sky,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.open_in_new_rounded,
                              color: Colors.white
                                  .withValues(alpha: 0.30),
                              size: 16),
                        ]),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],

                  const SizedBox(height: 32),
                  // Reviews — clients only (must be logged in)
                  ReviewsSection(productId: product.id),
                  const SizedBox(height: 32),
                  ShareQrSection(product: product),

                  // Admin dashboard button
                  if (isAdmin) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/admin'),
                        icon: const Icon(Icons.admin_panel_settings_rounded,
                            size: 16, color: AppColors.teal),
                        label: const Text('Back to Admin Dashboard',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                                fontWeight: FontWeight.w600, color: AppColors.teal)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.teal),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  // Innovator dashboard button
                  if (isInnovator) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/innovator/dashboard'),
                        icon: const Icon(Icons.dashboard_rounded,
                            size: 16, color: AppColors.teal),
                        label: const Text('Back to Innovator Dashboard',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                                fontWeight: FontWeight.w600, color: AppColors.teal)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.teal),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

<<<<<<< HEAD
      // ── Bottom action bar ─────────────────────────────────
      bottomNavigationBar: Container(
=======
      // Bottom bar — clients only (full interaction)
      bottomNavigationBar: !isClient ? null : Container(
>>>>>>> origin/master
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.midnight,
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
<<<<<<< HEAD
        child: isLoggedIn
            ? Row(children: [
                // Like button
                GestureDetector(
                  onTap: () async {
                    setState(() => _liked = !_liked);
                    final ok = await ref.read(marketplaceProvider.notifier).likeProduct(product.id);
                    if (!ok && context.mounted) {
                      setState(() => _liked = !_liked);
                    }
                  },
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _liked
                            ? AppColors.crimson.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _liked
                              ? AppColors.crimson.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                        boxShadow: _liked
                            ? [
                                BoxShadow(
                                  color: AppColors.crimson
                                      .withValues(alpha: 0.25),
                                  blurRadius: 12,
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: _liked
                                ? AppColors.crimson
                                : Colors.white.withValues(alpha: 0.45),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${product.likes + (_liked ? 1 : 0)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _liked
                                  ? AppColors.crimson
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Express Interest — golden gradient button
                  Expanded(
                    child: _interestSent
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    AppColors.teal.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded,
                                    color: AppColors.teal, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Interest Sent!',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() => _interestSent = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Interest expressed! The innovator will be notified.',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  backgroundColor: AppColors.golden,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              );
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.golden,
                                    AppColors.warmEmber,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.golden.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.handshake_rounded,
                                      color: AppColors.navy, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Express Interest',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
              ])
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.golden, AppColors.warmEmber],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => context.go('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign In to Interact',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.navy)),
                ),
              ),
=======
        child: Row(children: [
          // Like
          GestureDetector(
            onTap: () async {
              setState(() => _liked = !_liked);
              final ok = await ref.read(marketplaceProvider.notifier).likeProduct(product.id);
              if (!ok && context.mounted) {
                setState(() => _liked = !_liked);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Could not update like.',
                      style: TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: AppColors.crimson, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: _liked ? AppColors.crimson.withValues(alpha: 0.1)
                    : isDark ? const Color(0xFF1A2233) : AppColors.offWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _liked ? AppColors.crimson : borderCol),
              ),
              child: Row(children: [
                Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _liked ? AppColors.crimson : Colors.black38, size: 20),
                const SizedBox(width: 6),
                Text('${product.likes + (_liked ? 1 : 0)}',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _liked ? AppColors.crimson : Colors.black38)),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          // Express Interest
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _interestSent ? null : () async {
                final ok = await ref
                    .read(marketplaceProvider.notifier)
                    .expressInterest(product.id);
                if (!context.mounted) return;
                if (ok) {
                  setState(() => _interestSent = true);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Interest expressed! The innovator will be notified.',
                        style: TextStyle(fontFamily: 'Poppins')),
                    backgroundColor: AppColors.teal, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Could not send interest. Please try again.',
                        style: TextStyle(fontFamily: 'Poppins')),
                    backgroundColor: AppColors.crimson, behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _interestSent ? AppColors.lightGray : color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: _interestSent ? 0 : 4,
              ),
              icon: Icon(_interestSent ? Icons.check_rounded : Icons.handshake_rounded,
                  color: Colors.white, size: 18),
              label: Text(_interestSent ? 'Interest Sent!' : 'Express Interest',
                  style: const TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
            ),
          ),
        ]),
>>>>>>> origin/master
      ),
    );
  }

  Widget _buildLabel(String title, IconData icon, Color textColor) {
    return Row(children: [
      Icon(icon, size: 18, color: textColor),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
          fontWeight: FontWeight.w800, color: textColor)),
    ]);
  }

  Widget _buildImageGallery(ProductModel product, Color color) {
    return Stack(children: [
      PageView.builder(
        controller: _pageCtrl,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: product.images.length,
        itemBuilder: (_, i) {
          try {
            return GestureDetector(
              onTap: () => _openImageViewer(context, product.images, i),
              child: Image.memory(base64Decode(product.images[i]),
                  fit: BoxFit.cover, width: double.infinity),
            );
          } catch (_) {
            return Container(color: AppColors.richNavy);
          }
        },
      ),
      // Cinematic gradient overlay — darker at top and bottom
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.75),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ),
      // Page dots
      if (product.images.length > 1)
        Positioned(
          bottom: 86,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              product.images.length,
              (i) => AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? AppColors.golden
                      : Colors.white.withValues(alpha: 0.40),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: _currentPage == i
                      ? [
                          BoxShadow(
                            color:
                                AppColors.golden.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : [],
                ),
              ),
            ),
          ),
        ),
      _buildHeroContent(product, color),
    ]);
  }

  Widget _buildGradientFallback(ProductModel product, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepVoid,
            AppColors.richNavy,
            color.withValues(alpha: 0.25),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Grid texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          // Category icon watermark
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.07,
              child: Icon(
                _categoryIcon(product.category),
                size: 260,
                color: color,
              ),
            ),
          ),
          // Orb accent
          Positioned(
            left: -40,
            top: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          _buildHeroContent(product, color),
        ],
      ),
    );
  }

  Widget _buildHeroContent(ProductModel product, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Category + KYC badges
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: color.withValues(alpha: 0.45)),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (product.isVerifiedInnovator) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.teal.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Product name with golden accent
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE8E8E8)],
            ).createShader(bounds),
            child: Text(
              product.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _HeroStat(
                icon: Icons.favorite_rounded,
                value: '${product.likes}',
                label: 'Likes',
                color: AppColors.crimson,
              ),
              const SizedBox(width: 24),
              _HeroStat(
                icon: Icons.remove_red_eye_rounded,
                value: '${product.views}',
                label: 'Views',
                color: AppColors.sky,
              ),
              const SizedBox(width: 24),
              _HeroStat(
                icon: Icons.trending_up_rounded,
                value: '${product.interestCount}',
                label: 'Interests',
                color: AppColors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Back Button ───────────────────────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: const Icon(Icons.arrow_back,
            color: Colors.white, size: 18),
      ),
      onPressed: onTap,
    );
  }
}

// ── Outline Action Button ─────────────────────────────────────────────────────
class _OutlineActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlineActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_OutlineActionButton> createState() =>
      _OutlineActionButtonState();
}

class _OutlineActionButtonState
    extends State<_OutlineActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.color.withValues(
                  alpha: _hovered ? 0.7 : 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.color),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glass Card ────────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Section Header with golden accent line ────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.golden, AppColors.warmEmber],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ── Full-screen Image Viewer ──────────────────────────────────────────────────
class _ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  const _ImageViewer({required this.images, required this.initialPage});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late PageController _ctrl;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _ctrl = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.images.length,
            itemBuilder: (_, i) {
              try {
                return InteractiveViewer(minScale: 0.8, maxScale: 5.0,
                  child: Center(child: Image.memory(
                      base64Decode(widget.images[i]), fit: BoxFit.contain)));
              } catch (_) {
                return const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white38, size: 64));
              }
            },
          ),
          Positioned(top: 48, right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.15)),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          // Page counter
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          Colors.white.withValues(alpha: 0.12)),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final String videoBase64;
  final String filename;
  const _VideoCard({required this.videoBase64, required this.filename});

  @override
  Widget build(BuildContext context) {
    return Container(
<<<<<<< HEAD
      decoration: BoxDecoration(
        color: AppColors.midnight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
=======
      decoration: BoxDecoration(color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12, offset: const Offset(0, 4))],
>>>>>>> origin/master
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(children: [
<<<<<<< HEAD
          // Dark gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050A12),
                  Color(0xFF061A2E),
                ],
              ),
            ),
          ),
          // Grid texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Icon(Icons.videocam_rounded,
                color: AppColors.golden.withValues(alpha: 0.25),
                size: 28),
          ),
          // Play button
          Center(
            child: GestureDetector(
              onTap: () {
                try {
                  final bytes = base64Decode(videoBase64);
                  final blob = html.Blob([bytes], 'video/mp4');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  html.window.open(url, '_blank');
                  Future.delayed(const Duration(seconds: 5),
                      () => html.Url.revokeObjectUrl(url));
                } catch (_) {}
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.golden.withValues(alpha: 0.40),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.navy, size: 40),
                  ),
                  const SizedBox(height: 14),
                  Text(filename,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.70),
                      )),
                  const SizedBox(height: 4),
                  Text('Tap to play in browser',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      )),
                ],
              ),
            ),
          ),
=======
          Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
          ))),
          Positioned(top: 12, left: 12,
            child: Icon(Icons.videocam_rounded,
                color: Colors.white.withValues(alpha: 0.2), size: 28)),
          Center(child: GestureDetector(
            onTap: () {
              try {
                final bytes = base64Decode(videoBase64);
                final blob = html.Blob([bytes], 'video/mp4');
                final url = html.Url.createObjectUrlFromBlob(blob);
                html.window.open(url, '_blank');
                Future.delayed(const Duration(seconds: 5),
                    () => html.Url.revokeObjectUrl(url));
              } catch (_) {}
            },
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white54, width: 2),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40)),
              const SizedBox(height: 12),
              Text(filename, style: const TextStyle(fontFamily: 'Poppins',
                  fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              const Text('Tap to play in browser', style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 11, color: Colors.white38)),
            ]),
          )),
>>>>>>> origin/master
        ]),
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color.withValues(alpha: 0.85), size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

<<<<<<< HEAD
class _DetailChip extends StatelessWidget {
=======
class _DetailChip extends ConsumerWidget {
>>>>>>> origin/master
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _DetailChip({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}