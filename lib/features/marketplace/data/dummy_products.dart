// lib/features/marketplace/data/dummy_products.dart

import '../../../core/models/product_model.dart';

// ── Dummy Innovator Accounts ──────────────────────────────────────────────────
class DummyInnovator {
  final int id;
  final String name;
  final String username;
  final String kycStatus;

  const DummyInnovator({
    required this.id,
    required this.name,
    required this.username,
    this.kycStatus = 'verified',
  });
}

const _innovators = [
  DummyInnovator(id: -1,  name: 'Ramon dela Cruz',    username: 'rdelacruz_agri'),
  DummyInnovator(id: -2,  name: 'Maria Santos',        username: 'msantos_food'),
  DummyInnovator(id: -3,  name: 'Dr. Jose Reyes',      username: 'jreyes_medtech'),
  DummyInnovator(id: -4,  name: 'Engr. Ana Villanueva',username: 'avillanueva_energy'),
  DummyInnovator(id: -5,  name: 'Carlo Mendoza',       username: 'cmendoza_ict'),
  DummyInnovator(id: -6,  name: 'Engr. Luis Bautista', username: 'lbautista_mfg'),
  DummyInnovator(id: -7,  name: 'Pia Ramos',           username: 'pramos_design'),
  DummyInnovator(id: -8,  name: 'Dr. Nena Florendo',   username: 'nflorendo_biotech'),
  DummyInnovator(id: -9,  name: 'Engr. Mark Quisumbing',username: 'mquisumbing_solar'),
  DummyInnovator(id: -10, name: 'Liza Macaraeg',       username: 'lmacaraeg_tech'),
  DummyInnovator(id: -11, name: 'Engr. Dante Soriano', username: 'dsoriano_smart'),
  DummyInnovator(id: -12, name: 'Grace Navarro',       username: 'gnavarro_creative'),
  DummyInnovator(id: -13, name: 'Dr. Ben Castillo',    username: 'bcastillo_agtech'),
  DummyInnovator(id: -14, name: 'Fe Cabrera',          username: 'fcabrera_food'),
  DummyInnovator(id: -15, name: 'Engr. Rico Padilla',  username: 'rpadilla_ict'),
];

// ── Helper ────────────────────────────────────────────────────────────────────
ProductModel _dummy({
  required int id,
  required String name,
  required String description,
  required String category,
  required List<String> imageUrls,
  required DummyInnovator innovator,
  required int likes,
  required int views,
  required int interests,
  String? videoUrl,
  String? externalLink,
}) =>
    ProductModel(
      id:                   id,
      name:                 name,
      description:          description,
      category:             category,
      images:               imageUrls, // URL strings, not base64
      likes:                likes,
      views:                views,
      interestCount:        interests,
      status:               'approved',
      innovatorName:        innovator.name,
      innovatorUsername:    innovator.username,
      innovatorId:          innovator.id,
      kycStatus:            innovator.kycStatus,
      createdAt:            DateTime(2025, 6, 1),
      videoBase64:          videoUrl,   // reused field for demo video URL
      externalLink:         externalLink,
      isDraft:              false,
    );

// ── The 15 Dummy Products ─────────────────────────────────────────────────────
final List<ProductModel> dummyProducts = [

  // 1 ── Agri-Aqua and Forestry
  _dummy(
    id: -1,
    name: 'SmartFarm Sensor Suite',
    description:
        'An IoT-based precision agriculture system designed for Northern Mindanao\'s pineapple and banana plantations. '
        'The suite includes soil moisture sensors, weather stations, and automated irrigation controllers — '
        'reducing water usage by 40% and increasing yield by up to 25%. '
        'Fully compatible with existing DOST-funded farm infrastructure and validated in partnership with DA Region X.',
    category: 'Agri-Aqua and Forestry',
    imageUrls: [
      'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800',
      'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800',
      'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
    ],
    innovator: _innovators[0],
    likes: 142, views: 980, interests: 34,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://dost.gov.ph/programs/smart-agriculture',
  ),

  // 2 ── Food Processing and Nutrition
  _dummy(
    id: -2,
    name: 'VacFry Pro — Vacuum Frying System',
    description:
        'A low-temperature vacuum frying machine engineered for MSMEs in Bukidnon and CDO processing tropical fruits '
        'like jackfruit, mango, and banana. Extends shelf life to 12 months without preservatives, '
        'retains 90% of natural nutrients, and is FDA-compliance ready. '
        'Designed with stainless-steel food-grade components certified under Philippine Food Safety Act standards.',
    category: 'Food Processing and Nutrition',
    imageUrls: [
      'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800',
      'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
      'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800',
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
    ],
    innovator: _innovators[1],
    likes: 198, views: 1240, interests: 56,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://www.fda.gov.ph/food/',
  ),

  // 3 ── Health and Medical Sciences
  _dummy(
    id: -3,
    name: 'HerbalDx — Point-of-Care Diagnostic Kit',
    description:
        'A rapid diagnostic kit derived from locally sourced Philippine medicinal plants, validated under DOST\'s '
        '"Tuklas Lunas" drug discovery program. HerbalDx detects early markers of dengue and leptospirosis '
        'in under 15 minutes using lateral flow immunoassay technology. '
        'Currently deployed in 12 rural health units across Region X with 94.7% sensitivity.',
    category: 'Health and Medical Sciences',
    imageUrls: [
      'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800',
      'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=800',
      'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800',
      'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=800',
    ],
    innovator: _innovators[2],
    likes: 267, views: 1890, interests: 78,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://dost.gov.ph/programs/tuklas-lunas',
  ),

  // 4 ── Energy, Utilities, and Environment
  _dummy(
    id: -4,
    name: 'BioWatt — Biomass Energy Converter',
    description:
        'A modular biomass gasification unit that converts agricultural waste — corn stalks, rice husks, '
        'and sugarcane bagasse — into clean electricity for industrial use. '
        'Reduces carbon footprint by 60% compared to diesel generators and saves up to ₱180,000/month in energy costs '
        'for medium-scale factories. Certified by DOE Region X and currently pilot-tested in 3 Bukidnon agro-industrial estates.',
    category: 'Energy, Utilities, and Environment',
    imageUrls: [
      'https://images.unsplash.com/photo-1466611653911-95081537e5b7?w=800',
      'https://images.unsplash.com/photo-1473341304170-971dccb5ac1e?w=800',
      'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=800',
      'https://images.unsplash.com/photo-1497435334941-8c899ee9e8e9?w=800',
    ],
    innovator: _innovators[3],
    likes: 312, views: 2100, interests: 91,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://doe.gov.ph/renewable-energy',
  ),

  // 5 ── ICT
  _dummy(
    id: -5,
    name: 'LogiTrack AI — MSME Inventory System',
    description:
        'An AI-powered inventory and supply chain management platform built for CDO\'s growing e-commerce MSMEs. '
        'Features real-time stock monitoring, automated reorder triggers, and Shopee/Lazada integration. '
        'Predictive maintenance alerts reduce machine downtime by 35% in pilot factories. '
        'Winner of the DOST-PCIEERD 2024 Innovation Challenge for Digitalization.',
    category: 'Information and Communications Technology (ICT)',
    imageUrls: [
      'https://images.unsplash.com/photo-1518186285589-2f7649de83e0?w=800',
      'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
    ],
    innovator: _innovators[4],
    likes: 445, views: 3200, interests: 112,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://pcieerd.dost.gov.ph/',
  ),

  // 6 ── Advanced Manufacturing
  _dummy(
    id: -6,
    name: 'IliganCNC — Precision Metal Fabricator',
    description:
        'A locally designed and assembled CNC milling machine built in Iligan City using Philippine-sourced steel components. '
        'Achieves ±0.01mm precision at 1,200 units/hour — competitive with imported alternatives at 40% lower cost. '
        'Designed for the Metals and Engineering cluster of Region X, with after-sales support and spare parts '
        'available nationwide through partner DTI fabrication centers.',
    category: 'Advanced Manufacturing and Engineering',
    imageUrls: [
      'https://images.unsplash.com/photo-1565043589221-1a6fd9ae45c7?w=800',
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800',
      'https://images.unsplash.com/photo-1504328345606-18bbc8c9d7d1?w=800',
      'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800',
    ],
    innovator: _innovators[5],
    likes: 189, views: 1450, interests: 67,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://dti.gov.ph/metals-and-engineering',
  ),

  // 7 ── Creative Industries
  _dummy(
    id: -7,
    name: 'AbacaForge — Sustainable Packaging Design',
    description:
        'An eco-friendly packaging solution for export-ready Philippine products using abaca fiber composites. '
        'CAD-aided designs achieve an 8.9/10 Market Aesthetic Score in international trade fairs. '
        'Fully biodegradable, with tensile strength 3x higher than standard kraft paper. '
        'Compliant with EU and US eco-packaging import standards. '
        'Backed by the Philippine Creative Industries Development Act and CITEM export programs.',
    category: 'Creative Industries and Product Design',
    imageUrls: [
      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800',
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800',
      'https://images.unsplash.com/photo-1493552152660-f915ab47ae9d?w=800',
    ],
    innovator: _innovators[6],
    likes: 356, views: 2780, interests: 89,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://citem.com.ph/',
  ),

  // 8 ── Additional: AquaSmart
  _dummy(
    id: -8,
    name: 'AquaSmart — Automated Aquaculture Feeder',
    description:
        'A solar-powered automated feeding system for tilapia and bangus fishponds in Bukidnon and Lanao del Norte. '
        'Uses computer vision to detect fish feeding behavior and adjusts feed amounts in real time, '
        'reducing feed waste by 32% and increasing fish weight gain by 18%. '
        'Wireless monitoring via mobile app with 7-day battery backup.',
    category: 'Agri-Aqua and Forestry',
    imageUrls: [
      'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
      'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
      'https://images.unsplash.com/photo-1501619951397-5ba40d0f75da?w=800',
      'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=800',
    ],
    innovator: _innovators[7],
    likes: 203, views: 1560, interests: 48,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://bfar.da.gov.ph/',
  ),

  // 9 ── Additional: SolarIrrigate
  _dummy(
    id: -9,
    name: 'SolarIrrigate — Off-Grid Farm Irrigation',
    description:
        'A standalone solar-powered drip irrigation system for upland farms in Bukidnon with no grid access. '
        'Each unit powers a 2-hectare coverage area, reducing irrigation labor costs by 70%. '
        'Modular design allows expansion up to 10 hectares. '
        'Reduces water consumption by 45% versus traditional flood irrigation. '
        'Currently deployed in 28 corn farms in Maramag and Valencia, Bukidnon.',
    category: 'Energy, Utilities, and Environment',
    imageUrls: [
      'https://images.unsplash.com/photo-1508193638397-1c4234db14d8?w=800',
      'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800',
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
    ],
    innovator: _innovators[8],
    likes: 178, views: 1320, interests: 52,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://nia.gov.ph/',
  ),

  // 10 ── Additional: RetortCan
  _dummy(
    id: -10,
    name: 'RetortCan — Pressure Canning System for MSMEs',
    description:
        'A compact retort processing unit designed for small food manufacturers in CDO and surrounding municipalities. '
        'Extends shelf life of ready-to-eat meals and canned goods to 24 months without refrigeration. '
        'FDA-LTO ready documentation included. Processes 200 cans per batch at 121°C sterilization temperature. '
        'Saves ₱60,000/month in cold storage costs for early adopters.',
    category: 'Agri-Aqua and Forestry',
    imageUrls: [
      'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=800',
      'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=800',
      'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=800',
      'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800',
    ],
    innovator: _innovators[9],
    likes: 234, views: 1780, interests: 71,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://www.fda.gov.ph/',
  ),

  // 11 ── Additional: TeleHealth CDO
  _dummy(
    id: -11,
    name: 'TeleHealth CDO — Rural Telemedicine Platform',
    description:
        'A telemedicine platform connecting rural health units in Region X to specialist doctors in CDO. '
        'Features real-time video consultation, electronic prescription, and AI-assisted triage. '
        'Integrated with PhilHealth for cashless consultation coverage. '
        'Reduced patient travel cost by average ₱1,200/visit across 15 partner RHUs. '
        'Recognized by DOH Region X as a flagship digital health initiative.',
    category: 'Health and Medical Sciences',
    imageUrls: [
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800',
      'https://images.unsplash.com/photo-1563213126-a4273aed2016?w=800',
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
      'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?w=800',
    ],
    innovator: _innovators[10],
    likes: 521, views: 4100, interests: 134,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://doh.gov.ph/digital-health',
  ),

  // 12 ── Additional: EcoWeave
  _dummy(
    id: -12,
    name: 'EcoWeave — Indigenous Textile Innovation',
    description:
        'A CAD-aided design system for Higaonon and Bukidnon indigenous textile patterns, enabling MSMEs '
        'to digitize and scale traditional weaving for export markets. '
        'Includes eco-friendly natural dye processing using locally sourced tannin compounds. '
        'Partner of the NCCA and DTI Go Lokal! program. '
        'Products currently sold in 4 international markets including Japan, Germany, and the US.',
    category: 'Creative Industries and Product Design',
    imageUrls: [
      'https://images.unsplash.com/photo-1558769132-cb1aea458c5e?w=800',
      'https://images.unsplash.com/photo-1493552152660-f915ab47ae9d?w=800',
      'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800',
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
    ],
    innovator: _innovators[11],
    likes: 389, views: 2950, interests: 103,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://ncca.gov.ph/',
  ),

  // 13 ── Additional: PhytoShield
  _dummy(
    id: -13,
    name: 'PhytoShield — Biopesticide from Makabuhay',
    description:
        'An organic biopesticide extracted from Tinospora rumphii (Makabuhay), a vine native to Mindanao. '
        'Effective against aphids, whiteflies, and fungal pathogens in pineapple and banana plantations. '
        'Reduces chemical pesticide use by 55% and meets organic certification requirements. '
        'Validated by PCAARRD and recommended by DA-BAI for nationwide distribution.',
    category: 'Agri-Aqua and Forestry',
    imageUrls: [
      'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
      'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800',
      'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
      'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800',
    ],
    innovator: _innovators[12],
    likes: 167, views: 1230, interests: 44,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://pcaarrd.dost.gov.ph/',
  ),

  // 14 ── Additional: NutriPack
  _dummy(
    id: -14,
    name: 'NutriPack — Fortified Ready-to-Cook Meals',
    description:
        'A nutrient-fortified ready-to-cook meal formulation targeting school feeding programs and disaster relief '
        'operations in Region X. Each pack provides 100% RDA of iron, vitamin A, and zinc for children 6-12. '
        'Shelf-stable for 18 months. Produced using locally sourced moringa, malunggay, and kangkong concentrates. '
        'Endorsed by DepEd Region X and currently supplying 42 public schools in Misamis Oriental.',
    category: 'Health and Medical Sciences',
    imageUrls: [
      'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800',
      'https://images.unsplash.com/photo-1547592180-85f173990554?w=800',
      'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800',
      'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=800',
    ],
    innovator: _innovators[13],
    likes: 412, views: 3100, interests: 98,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://deped.gov.ph/school-feeding',
  ),

  // 15 ── Additional: SmartBridge
  _dummy(
    id: -15,
    name: 'SmartBridge — MSME Digital Onboarding Platform',
    description:
        'A one-stop digital onboarding platform that helps CDO MSMEs register, comply, and connect to '
        'national e-commerce platforms in under 3 days. '
        'Features automated BIR, DTI, and FDA document preparation using AI form-filling. '
        'Integrated with GCash, Maya, and UnionBank for instant business account setup. '
        'Has onboarded 1,240 MSMEs in Region X since its soft launch in Q1 2024.',
    category: 'Information and Communications Technology (ICT)',
    imageUrls: [
      'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
      'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
      'https://images.unsplash.com/photo-1518186285589-2f7649de83e0?w=800',
      'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
    ],
    innovator: _innovators[14],
    likes: 634, views: 4800, interests: 156,
    videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    externalLink: 'https://dti.gov.ph/negosyo-center',
  ),
];

/// Returns true if a product is a dummy/demo post
bool isDummyProduct(int productId) => productId < 0;
