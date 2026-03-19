# DIGITAL PLATFORM UI Redesign — Shared Design Brief
# Read this before making ANY design decisions

## Brand Identity
- **Display Name**: "Digital Platform" ← USE THIS EVERYWHERE IN VISIBLE UI TEXT
- **Internal/Code name**: HIRAYA (keep all Dart class names, file names, routes unchanged)
- **Tagline**: "Where Filipino Innovation Soars"
- **Audience**: Filipino innovators, researchers, and enterprise clients
- **Feel**: Premium, cinematic, trustworthy, patriotic, tech-forward

## ⚠️ CRITICAL BRAND NAME RULE
ANY visible user-facing text that currently says "Hiraya" or "HIRAYA" MUST be changed to "Digital Platform".
This includes: navbar logos, page titles, auth screen headings, footer brand name, hero sections, CTA text, etc.
DO NOT change: Dart class names, file names, route paths, variable names, or comments.

## Design System — NON-NEGOTIABLE
All agents MUST use these exact values for uniformity:

### Color Palette (from AppColors)
```dart
crimson    = Color(0xFFD00000)   // Energy, danger, healthcare
golden     = Color(0xFFFFBA08)   // Primary accent, CTAs, brand highlight
sky        = Color(0xFF3F88C5)   // Info, secondary
navy       = Color(0xFF032B43)   // Dark text on light, deep panels
teal       = Color(0xFF136F63)   // Success, trust, security
warmEmber  = Color(0xFFFF6B35)   // Gradient partner with golden
deepVoid   = Color(0xFF050A12)   // Primary background (darkest)
midnight   = Color(0xFF0D1117)   // Secondary background
richNavy   = Color(0xFF061A2E)   // Panel backgrounds
darkSurface= Color(0xFF0F1923)   // Card backgrounds
borderDark = Color(0xFF1E2D3D)   // Card borders
goldSheen  = Color(0xFFFFD700)   // Special golden accent
```

### Primary Gradients
- **Hero gradient**: `[deepVoid, richNavy, Color(0xFF0A2240)]` (topLeft → bottomRight)
- **Golden CTA**: `[golden, warmEmber]` (left → right)
- **Teal trust**: `[teal, Color(0xFF0E5A50)]`
- **Glass card**: `Color(0xFF0F1923).withValues(alpha: 0.92)` with `borderDark` border

### Typography
- **Font**: Poppins (already loaded) — USE ONLY Poppins
- **Display**: w800–w900, -1 letterSpacing, white
- **Body**: w400–w500, 0.2 letterSpacing, white70
- **Caption**: w500–w600, 1–2 letterSpacing, white55
- **CTA**: w700, 14–16px, navy (on golden) or white (on teal/dark)

### Motion Principles (flutter_animate)
- Page load: staggered fadeIn + slideY(begin: 0.2), delays 200ms–1400ms
- Hover: scale 1.0→1.04, AnimatedContainer 200ms, Curves.easeOutCubic
- Press: scale 1.04→0.97
- Orbs: repeat(reverse:true) 5–8s, CurvedAnimation easeInOut
- Scroll-trigger: use VisibilityDetector or threshold-based setState
- Transitions: always easeOutCubic or easeInOutCubic
- Auth mode switch: AnimatedSwitcher or custom SlideTransition (400ms easeInOutCubic)

### Visual Language
- Animated glowing orbs (teal, golden, crimson, sky at 7–18% opacity)
- Subtle grid texture overlay (opacity 0.025, white lines)
- Glass morphism cards: dark semi-transparent bg + borderDark border
- Golden shimmer on text with ShaderMask + LinearGradient
- Hover glows: golden/teal boxShadow with blurRadius 16–24
- Section separators: gradient lines, not solid dividers
- Floating particle dots: subtle white dots at low opacity drifting slowly
- Aurora-like background gradients that animate slowly

### Layout
- Desktop breakpoint: >900px (two-column)
- Tablet: 600–900px
- Mobile: <600px
- Section padding: horizontal 80px desktop, 24px mobile
- Card border radius: 16px standard, 20px hero cards, 12px small
- Navbar height: 70px

## Section-specific Hero Heights
Each section that needs a hero:
- Landing: full viewport (size.height)
- Marketplace: 300px desktop, 220px mobile
- Auth screens: full viewport split (left panel + right form)
- Product Detail: 280px desktop, 200px mobile

## Auth Unified Screen Architecture
Tasks I–IV require a UNIFIED auth screen. Use this architecture:
- Single `UnifiedAuthScreen` widget in `lib/features/auth/screens/unified_auth_screen.dart`
- `AuthMode` enum: `login`, `signup`, `forgotPassword`
- Router updated: `/login`, `/signup`, `/forgot-password` all render `UnifiedAuthScreen` with `initialMode`
- Mode switching uses: `PageController` or `AnimatedSwitcher` + `SlideTransition`
- Desktop layout: Left decorative panel (brand visuals) + Right form card
- Mobile layout: Full screen form card with brand header
- LEFT PANEL: animated orbs, brand logo "Digital Platform", tagline, floating innovation stats
- RIGHT PANEL: glassmorphic form card with mode-specific fields

## Navigation Routing (go_router)
- `/` → Landing
- `/marketplace` → Marketplace
- `/marketplace?category=Agriculture` → Filtered marketplace
- `/product/:id` → Product detail
- `/login` → UnifiedAuthScreen (initialMode: login)
- `/signup` → UnifiedAuthScreen (initialMode: signup)
- `/forgot-password` → UnifiedAuthScreen (initialMode: forgotPassword)
- `/otp` → OTP screen
- `/admin` → Admin dashboard
- `/innovator/dashboard` → Innovator dashboard
- `/client/dashboard` → Client dashboard

## Animations Package
`flutter_animate` is installed — use `.animate()`, `.fadeIn()`, `.slideY()`, `.scale()`, `.shimmer()`, `.then()`, etc.

## Required Packages (already in pubspec)
- flutter_animate
- flutter_riverpod
- go_router
- shimmer (for skeleton loading)
- file_picker
- firebase_auth

## Hero Section Template
Every section hero must have:
1. Gradient background matching the section's category color
2. Animated orbs (2–3 minimum)
3. Particle/grid texture overlay
4. Title + subtitle with staggered entrance animations
5. Interactive element (search bar / category pills / CTA button)
6. Scroll-down indicator (bottom of hero only for landing)

## Skeleton Loading Principles (Task IX — ENHANCED)
- Use custom AnimationController (already in shimmer_skeleton.dart)
- Each screen section gets its OWN skeleton variant that mirrors the actual layout
- Skeleton must MIRROR the actual content layout precisely
- Use rounded rectangles for text placeholders
- Use square/circle placeholders for images/icons
- Card skeletons for product cards
- Navbar skeleton for loading state
- Color: darkSurface base + borderDark shimmer highlight
- Add PULSE animation (opacity fade 0.4→0.8→0.4) layered with shimmer sweep
- Add WAVE stagger: each block animates with offset delay (50ms per block)
- Named variants: ShimmerSkeleton.productCard, ShimmerSkeleton.marketplaceHero,
  ShimmerSkeleton.landingHero, ShimmerSkeleton.authCard, ShimmerSkeleton.navBar,
  ShimmerSkeleton.productDetail, ShimmerSkeleton.profileCard, ShimmerSkeleton.categoryGrid

## About Section (= FeaturesSection "Why Digital Platform?")
- Located in landing page FeaturesSection
- Nav "About" link → scroll to FeaturesSection
- Add: mission statement, team count, university partners, innovation stats
- Keep cinematic appearance

## Categories Navigation
- Categories dropdown in navbar → `/marketplace?category=X`
- Landing CategoryGrid → same routing
- Dropdown must be animated (slide down + fade in, not just showMenu)

## Trending Design Patterns to Apply
- **Glassmorphism**: backdrop blur + semi-transparent panels
- **Aurora backgrounds**: slowly shifting color blobs
- **Bento grid layouts**: asymmetric grid for feature sections
- **Floating elements**: cards that hover with subtle shadow changes on scroll
- **Gradient text**: golden→warmEmber gradient on hero headings
- **Reveal animations**: elements slide up as they enter viewport
- **Magnetic hover**: subtle card tilt effect on hover
- **Particle systems**: low-opacity floating dots
- **Split layouts**: diagonal section dividers
- **Number counters**: animated stat counters when in view

## DO NOT
- Do not change routing logic paths (go_router paths stay the same)
- Do not modify Firebase/API service calls
- Do not change provider logic
- Do not add new packages without checking pubspec.yaml first
- Do not use any font other than Poppins
- Do not use purple gradients or generic color schemes
- Do not break existing screen navigation flow
- Do NOT use the word "Hiraya" in any user-visible UI text
