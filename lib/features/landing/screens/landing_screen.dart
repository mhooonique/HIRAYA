import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/parallax_hero.dart';
import '../widgets/category_grid.dart';
import '../widgets/features_section.dart';
import '../widgets/landing_navbar.dart';
import '../widgets/innovation_carousel.dart';
import '../widgets/cta_section.dart';
import '../widgets/landing_footer.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // Anchor keys for navbar links
  final _categoryKey = GlobalKey();
  final _featuresKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: LandingNavbar(
          scrollOffset: _scrollOffset,
          onAboutTap: () => _scrollTo(_featuresKey),
          onCategoriesTap: () => _scrollTo(_categoryKey),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 1. Hero with Parallax
            ParallaxHero(scrollOffset: _scrollOffset),

            // 2. Category Grid
            CategoryGrid(key: _categoryKey),

            // 3. Innovation Carousel
            const InnovationCarousel(),

            // 4. Features Section ("Why HIRAYA?")
            FeaturesSection(key: _featuresKey),

            // 5. CTA Section
            const CtaSection(),

            // 6. Footer
            const LandingFooter(),
          ],
        ),
      ),
    );
  }
}
