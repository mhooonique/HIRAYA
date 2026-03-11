import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../widgets/parallax_hero.dart';
import '../widgets/category_grid.dart';
import '../widgets/features_section.dart';
import '../widgets/landing_navbar.dart';
import '../widgets/innovation_carousel.dart';
import '../widgets/cta_section.dart';
import '../widgets/landing_footer.dart';
import '../widgets/landing_skeleton.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  double _scrollProgress = 0; // 0..1 for the progress bar
  bool _showSkeleton = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Dismiss skeleton after first frame is painted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _showSkeleton = false);
      });
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    double progress = 0;
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      progress = (offset / _scrollController.position.maxScrollExtent)
          .clamp(0.0, 1.0);
    }
    setState(() {
      _scrollOffset = offset;
      _scrollProgress = progress;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: LandingNavbar(
          scrollOffset: _scrollOffset,
          scrollProgress: _scrollProgress,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
        child: _showSkeleton
            ? const LandingSkeleton(key: ValueKey('skeleton'))
            : SingleChildScrollView(
                key: const ValueKey('content'),
                controller: _scrollController,
                child: const Column(
                  children: [
                    // 1. Hero with Parallax — passes scroll for parallax
                    _ScrollAwarHero(),

                    // 2. Category Grid
                    CategoryGrid(),

                    // 3. Innovation Carousel
                    InnovationCarousel(),

                    // 4. Features / Why HIRAYA
                    FeaturesSection(),

                    // 5. CTA — Ready to Showcase
                    CtaSection(),

                    // 6. Footer
                    LandingFooter(),
                  ],
                ),
              ),
      ),
    );
  }
}

// Helper that reads the scroll offset from the scroll notification
// so ParallaxHero can use it without a global setState on every pixel.
class _ScrollAwarHero extends StatefulWidget {
  const _ScrollAwarHero();

  @override
  State<_ScrollAwarHero> createState() => _ScrollAwarHeroState();
}

class _ScrollAwarHeroState extends State<_ScrollAwarHero> {
  double _offset = 0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollUpdateNotification) {
          setState(() => _offset = n.metrics.pixels);
        }
        return false;
      },
      child: ParallaxHero(scrollOffset: _offset),
    );
  }
}