import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class LandingNavbar extends StatelessWidget {
  final double scrollOffset;
  const LandingNavbar({super.key, required this.scrollOffset});

  void _showMobileMenu(BuildContext context) {
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Image.asset('assets/images/logo/final-logo.png', height: 32),
                const SizedBox(width: 10),
                const Text('HIRAYA', style: TextStyle(
                  fontFamily: 'Poppins', color: Colors.white,
                  fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2,
                )),
              ]),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              _MobileMenuItem(
                icon: Icons.storefront_rounded,
                label: 'Marketplace',
                onTap: () { Navigator.pop(rootContext); rootContext.go('/marketplace'); },
              ),
              _MobileMenuItem(
                icon: Icons.info_outline_rounded,
                label: 'About',
                onTap: () => Navigator.pop(rootContext),
              ),
              _MobileMenuItem(
                icon: Icons.category_outlined,
                label: 'Categories',
                onTap: () => Navigator.pop(rootContext),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () { Navigator.pop(rootContext); rootContext.go('/login'); },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sign In', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15,
                  )),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(rootContext); rootContext.go('/signup'); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Get Started', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                    fontSize: 15, color: Colors.white,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isScrolled = scrollOffset > 50;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isScrolled
            ? AppColors.navy.withOpacity(0.97)
            : Colors.transparent,
        boxShadow: isScrolled
            ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12)]
            : [],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 12,
          ),
          child: Row(
            children: [
              Image.asset('assets/images/logo/final-logo.png', height: isMobile ? 32 : 40),
              const SizedBox(width: 10),
              Text(
                'HIRAYA',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              if (!isMobile) ...[
                _NavLink(label: 'Marketplace', onTap: () => context.go('/marketplace')),
                const _NavLink(label: 'About'),
                const _NavLink(label: 'Categories'),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Sign In', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                  )),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => context.go('/signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Get Started', style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                  )),
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                  onPressed: () => _showMobileMenu(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MobileMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(label, style: const TextStyle(
        fontFamily: 'Poppins', color: Colors.white,
        fontSize: 15, fontWeight: FontWeight.w500,
      )),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _NavLink({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Text(label, style: const TextStyle(
          color: Colors.white, fontFamily: 'Poppins',
          fontWeight: FontWeight.w500, fontSize: 14,
        )),
      ),
    );
  }
}