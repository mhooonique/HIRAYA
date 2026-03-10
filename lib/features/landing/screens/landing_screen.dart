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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: LandingNavbar(scrollOffset: _scrollOffset),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 1. Hero with Parallax
            ParallaxHero(scrollOffset: _scrollOffset),

            // 2. Category Grid
            const CategoryGrid(),

            // 3. Innovation Carousel
            const InnovationCarousel(),

            // 4. Features Section
            const FeaturesSection(),

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