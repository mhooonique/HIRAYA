// lib/features/product/screens/demo_product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/share_qr_section.dart';

class DemoProductScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  const DemoProductScreen({super.key, required this.product});

  @override
  ConsumerState<DemoProductScreen> createState() => _DemoProductScreenState();
}

class _DemoProductScreenState extends ConsumerState<DemoProductScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _interestSent = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) =>
      AppColors.categoryColors[cat] ?? AppColors.navy;

  void _goBack() {
    if (context.canPop()) context.pop();
    else context.go('/marketplace');
  }

  @override
  Widget build(BuildContext context) {
    final p            = widget.product;
    final color        = _categoryColor(p.category);
    final isDark       = ref.watch(themeProvider) == ThemeMode.dark;
    final auth         = ref.watch(authProvider);
    final role         = auth.user?.role ?? '';
    final isLoggedIn   = auth.isLoggedIn;
    final isClient     = isLoggedIn && role == 'client';
    final isRestricted = isLoggedIn && (role == 'admin' || role == 'innovator');

    final cardBg        = isDark ? const Color(0xFF1A2233) : Colors.white;
    final borderCol     = isDark ? const Color(0xFF2A3448) : AppColors.lightGray;
    final primaryText   = isDark ? Colors.white : AppColors.navy;
    final secondaryText = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.offWhite,
      body: CustomScrollView(
        slivers: [
          // ── Hero ─────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: _goBack,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.science_rounded, color: AppColors.golden, size: 14),
                      SizedBox(width: 6),
                      Text('DEMO',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w700, color: AppColors.golden,
                              letterSpacing: 1)),
                    ]),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(background: _buildHero(p, color)),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Demo notice
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.golden.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.golden.withValues(alpha: 0.4)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.golden, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This is a showcase post. Sign in to interact with real innovations.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                              color: AppColors.golden),
                        ),
                      ),
                    ]),
                  ).animate().fadeIn(),

                  // Innovator card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Text(
                          p.innovatorName.isNotEmpty
                              ? p.innovatorName[0].toUpperCase() : 'I',
                          style: TextStyle(fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700, color: color, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.innovatorName, style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 15, fontWeight: FontWeight.w700, color: primaryText)),
                          Text('@${p.innovatorUsername}', style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black45)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                        ),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_rounded, color: AppColors.teal, size: 12),
                          SizedBox(width: 4),
                          Text('Verified', style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 11, color: AppColors.teal,
                              fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ]),
                  ).animate().fadeIn(duration: 400.ms),

                  // Guest sign-in banner
                  if (!isLoggedIn) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sky.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.sky.withValues(alpha: 0.4)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.sky, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(TextSpan(
                              style: TextStyle(fontFamily: 'Poppins',
                                  fontSize: 12, color: AppColors.sky),
                              children: [
                                TextSpan(text: 'Join as a CLIENT '),
                                TextSpan(
                                    text: 'to like, message, bookmark, and express interest.',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            )),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: AppColors.sky, size: 14),
                        ]),
                      ),
                    ).animate().fadeIn(),
                  ],

                  // ── Gallery ───────────────────────────────────────────────
                  if (p.images.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLabel('Gallery', Icons.photo_library_rounded, primaryText),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 600,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          itemCount: p.images.length,
                          itemBuilder: (_, i) => Image.network(
                            p.images[i],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : Container(
                                        color: color.withValues(alpha: 0.1),
                                        child: Center(
                                            child: CircularProgressIndicator(
                                                color: color, strokeWidth: 2))),
                            errorBuilder: (_, __, ___) => Container(
                              color: color.withValues(alpha: 0.1),
                              child: Icon(Icons.image_rounded,
                                  color: color, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          p.images.length,
                          (i) => AnimatedContainer(
                                duration: 200.ms,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentPage == i ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentPage == i
                                      ? color
                                      : color.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              )),
                    ),
                  ],

                  // ── Video Demo ────────────────────────────────────────────
                  if (p.videoBase64 != null && p.videoBase64!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLabel('Video Demo', Icons.videocam_rounded, primaryText),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(p.videoBase64!),
                          mode: LaunchMode.externalApplication),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [color, color.withValues(alpha: 0.7)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_rounded,
                                color: Colors.white, size: 48),
                            SizedBox(width: 14),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Watch Demo Video',
                                    style: TextStyle(fontFamily: 'Poppins',
                                        fontSize: 16, fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                                Text('Opens in browser',
                                    style: TextStyle(fontFamily: 'Poppins',
                                        fontSize: 12, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
                  ],

                  // ── About ─────────────────────────────────────────────────
                  const SizedBox(height: 24),
                  _buildLabel('About this Innovation',
                      Icons.lightbulb_rounded, primaryText),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol)),
                    child: Text(p.description,
                        style: TextStyle(fontFamily: 'Poppins',
                            fontSize: 14, color: secondaryText, height: 1.7)),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // Stats
                  Row(children: [
                    _StatChip(Icons.favorite_rounded,
                        '${p.likes}', 'Likes', AppColors.crimson),
                    const SizedBox(width: 12),
                    _StatChip(Icons.remove_red_eye_rounded,
                        '${p.views}', 'Views', AppColors.sky),
                    const SizedBox(width: 12),
                    _StatChip(Icons.handshake_rounded,
                        '${p.interestCount}', 'Interests', AppColors.teal),
                  ]).animate(delay: 150.ms).fadeIn(),

                  // External link
                  if (p.externalLink != null && p.externalLink!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildLabel('Learn More', Icons.link_rounded, primaryText),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(p.externalLink!),
                          mode: LaunchMode.externalApplication),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.sky.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.open_in_new_rounded,
                                color: AppColors.sky, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text('Official Reference Link',
                                    style: TextStyle(fontFamily: 'Poppins',
                                        fontSize: 14, fontWeight: FontWeight.w700,
                                        color: primaryText)),
                                Text(p.externalLink!,
                                    style: const TextStyle(fontFamily: 'Poppins',
                                        fontSize: 12, color: AppColors.sky),
                                    overflow: TextOverflow.ellipsis),
                              ])),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.black38),
                        ]),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],

                  // QR Section
                  const SizedBox(height: 32),
                  ShareQrSection(product: p),
                  const SizedBox(height: 32),

                  // ── CTA based on role ─────────────────────────────────────

                  // Guest → Sign In to Interact
                  if (!isLoggedIn)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.15),
                            color.withValues(alpha: 0.05)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Column(children: [
                        Icon(Icons.rocket_launch_rounded, color: color, size: 36),
                        const SizedBox(height: 12),
                        Text('Interested in this innovation?',
                            style: TextStyle(fontFamily: 'Poppins',
                                fontSize: 16, fontWeight: FontWeight.w700,
                                color: primaryText)),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to connect with the innovator, '
                          'express interest, and explore more.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins',
                              fontSize: 13, color: secondaryText),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Sign In to Interact',
                                style: TextStyle(fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700, fontSize: 15,
                                    color: Colors.white)),
                          ),
                        ),
                      ]),
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0)

                  // Client → Express Interest
                  else if (isClient)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _interestSent
                            ? null
                            : () {
                                setState(() => _interestSent = true);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: const Text(
                                    'Interest noted! This is a showcase — '
                                    'explore real innovations to connect.',
                                    style: TextStyle(fontFamily: 'Poppins'),
                                  ),
                                  backgroundColor: AppColors.teal,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ));
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _interestSent ? AppColors.lightGray : color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: _interestSent ? 0 : 4,
                        ),
                        icon: Icon(
                            _interestSent
                                ? Icons.check_rounded
                                : Icons.handshake_rounded,
                            color: Colors.white,
                            size: 18),
                        label: Text(
                            _interestSent ? 'Interest Noted!' : 'Express Interest',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Colors.white)),
                      ),
                    ).animate(delay: 200.ms).fadeIn()

                  // Admin / Innovator → nothing
                  else
                    const SizedBox.shrink(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ProductModel p, Color color) {
    return Stack(children: [
      p.images.isNotEmpty
          ? Image.network(p.images.first,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.7)]))))
          : Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.7)]))),
      Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          stops: const [0.3, 1.0],
        ),
      ))),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: Text(p.category,
                  style: const TextStyle(fontFamily: 'Poppins',
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(p.name,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 28,
                    fontWeight: FontWeight.w800, color: Colors.white,
                    height: 1.2)),
            const SizedBox(height: 16),
            Row(children: [
              _HeroStat(Icons.favorite_rounded, '${p.likes}', 'Likes'),
              const SizedBox(width: 20),
              _HeroStat(Icons.remove_red_eye_rounded, '${p.views}', 'Views'),
              const SizedBox(width: 20),
              _HeroStat(Icons.trending_up_rounded,
                  '${p.interestCount}', 'Interests'),
            ]),
          ],
        ),
      ),
    ]);
  }

  Widget _buildLabel(String title, IconData icon, Color textColor) {
    return Row(children: [
      Icon(icon, size: 18, color: textColor),
      const SizedBox(width: 8),
      Text(title,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
              fontWeight: FontWeight.w800, color: textColor)),
    ]);
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _HeroStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(fontFamily: 'Poppins',
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
          Text(label,
              style: const TextStyle(fontFamily: 'Poppins',
                  fontSize: 11, color: Colors.white60)),
        ],
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatChip(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                    fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: const TextStyle(fontFamily: 'Poppins',
                    fontSize: 11, color: Colors.black45)),
          ]),
        ),
      );
}