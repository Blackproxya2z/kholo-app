/// A curated care product in the KHOLO catalog.
class Product {
  final String id;
  final String title;
  final String category;   // e.g. 'Cycle care', 'Pregnancy comfort'
  final String description;
  final String usage;
  final List<String> ingredients;
  final double priceBdt;   // BDT price (whole taka)
  final String? imageUrl;
  final bool isAvailable;
  final List<String> tags;   // life stage / material tags

  const Product({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.usage,
    this.ingredients = const [],
    required this.priceBdt,
    this.imageUrl,
    this.isAvailable = true,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'usage': usage,
    'ingredients': ingredients,
    'priceBdt': priceBdt,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'tags': tags,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    description: json['description'] as String,
    usage: json['usage'] as String,
    ingredients: (json['ingredients'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    priceBdt: (json['priceBdt'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String?,
    isAvailable: json['isAvailable'] as bool? ?? true,
    tags: (json['tags'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
  );
}

/// Product categories aligned with PRD.
const List<String> kProductCategories = [
  'All',
  'Cycle care',
  'Fertility support',
  'Pregnancy comfort',
  'Postpartum care',
  'Newborn essentials',
  'Baby care',
];

/// Price bands for filtering.
const List<String> kPriceBands = [
  'All prices',
  'Under ৳500',
  '৳500 – ৳1,000',
  '৳1,000 – ৳2,000',
  'Above ৳2,000',
];

/// Checks if [price] falls in [band].
bool priceInBand(double price, String band) {
  switch (band) {
    case 'Under ৳500':
      return price < 500;
    case '৳500 – ৳1,000':
      return price >= 500 && price <= 1000;
    case '৳1,000 – ৳2,000':
      return price > 1000 && price <= 2000;
    case 'Above ৳2,000':
      return price > 2000;
    default:
      return true;
  }
}

/// Sample curated catalog (replaces a server catalog at production).
const List<Product> kSampleProducts = [
  Product(
    id: 'p001',
    title: 'Warm Comfort Heat Patch',
    category: 'Cycle care',
    description: 'A gentle, disposable heat patch for lower-back and abdominal comfort during your period. Lasts up to 8 hours.',
    usage: 'Apply to clothing over the lower abdomen or back. Do not apply directly to skin.',
    ingredients: ['Iron powder', 'Salt', 'Activated carbon', 'Water', 'Vermiculite'],
    priceBdt: 350,
    isAvailable: true,
    tags: ['Menstrual', 'Pain relief', 'Disposable'],
  ),
  Product(
    id: 'p002',
    title: 'Calming Lavender Bath Soak',
    category: 'Cycle care',
    description: 'An Epsom-salt blend with Bulgarian lavender essential oil to ease tension and support restful sleep before your period.',
    usage: 'Add 2–3 tablespoons to a warm bath. Soak for 15–20 minutes.',
    ingredients: ['Magnesium sulfate (Epsom salt)', 'Lavandula angustifolia oil', 'Dead Sea salt'],
    priceBdt: 620,
    isAvailable: true,
    tags: ['Menstrual', 'Self-care', 'Relaxation'],
  ),
  Product(
    id: 'p003',
    title: 'Cycle-Support Herbal Tea Blend',
    category: 'Fertility support',
    description: 'A caffeine-free blend of raspberry leaf, nettle, and chamomile. Traditionally used to support nutritional balance.',
    usage: 'Steep one teabag in hot water for 5 minutes. Enjoy up to two cups daily.',
    ingredients: ['Raspberry leaf', 'Nettle leaf', 'Chamomile flowers', 'Rosehip'],
    priceBdt: 480,
    isAvailable: true,
    tags: ['Fertility support', 'Herbal', 'Caffeine-free'],
  ),
  Product(
    id: 'p004',
    title: 'Gentle Pregnancy Body Oil',
    category: 'Pregnancy comfort',
    description: 'A light, fast-absorbing oil formulated to keep skin supple and moisturised during pregnancy. Fragrance-free.',
    usage: 'Massage a small amount into abdomen, hips, and thighs daily after bathing.',
    ingredients: ['Sweet almond oil', 'Rosehip seed oil', 'Vitamin E', 'Jojoba oil'],
    priceBdt: 890,
    isAvailable: true,
    tags: ['Pregnancy', 'Fragrance-free', 'Body care'],
  ),
  Product(
    id: 'p005',
    title: 'Maternity Support Pillow',
    category: 'Pregnancy comfort',
    description: 'A C-shaped pillow for side sleeping support during pregnancy. Machine-washable cotton cover.',
    usage: 'Place between knees and under abdomen for side-sleeping support.',
    ingredients: ['Hollow fibre fill', '100% cotton cover'],
    priceBdt: 1850,
    isAvailable: true,
    tags: ['Pregnancy', 'Sleep', 'Support'],
  ),
  Product(
    id: 'p006',
    title: 'Postpartum Sitz Salt Blend',
    category: 'Postpartum care',
    description: 'A mineral salt blend with witch hazel and calendula, formulated to support postpartum perineal comfort.',
    usage: 'Dissolve 4 tablespoons in a warm shallow sitz bath. Use as directed by your care provider.',
    ingredients: ['Sea salt', 'Epsom salt', 'Hamamelis virginiana (witch hazel)', 'Calendula extract'],
    priceBdt: 540,
    isAvailable: true,
    tags: ['Postpartum', 'Recovery', 'Natural'],
  ),
  Product(
    id: 'p007',
    title: 'Organic Nursing Pads (24-pack)',
    category: 'Postpartum care',
    description: 'Reusable organic cotton nursing pads with a waterproof bamboo layer. Soft and breathable.',
    usage: 'Wash before first use. Change pads as needed to keep skin dry.',
    ingredients: ['Organic cotton', 'Bamboo fibre', 'TPU waterproof layer'],
    priceBdt: 760,
    isAvailable: true,
    tags: ['Postpartum', 'Nursing', 'Reusable', 'Organic'],
  ),
  Product(
    id: 'p008',
    title: 'Newborn Swaddle Muslin Set (3-pack)',
    category: 'Newborn essentials',
    description: 'A trio of 120 × 120 cm muslin swaddles in gentle, non-printed organic cotton. Safe for sensitive newborn skin.',
    usage: 'Use for swaddling, nursing cover, pram shade, or play mat.',
    ingredients: ['100% GOTS-certified organic cotton muslin'],
    priceBdt: 1200,
    isAvailable: true,
    tags: ['Newborn', 'Organic', 'Swaddle'],
  ),
  Product(
    id: 'p009',
    title: 'Gentle Baby Wash & Shampoo',
    category: 'Baby care',
    description: 'A tearless, fragrance-free wash for hair and body, tested on sensitive skin. No sulphates or parabens.',
    usage: 'Apply a small amount to wet skin or hair, lather gently, and rinse thoroughly.',
    ingredients: ['Aqua', 'Coco-glucoside', 'Glycerin', 'Chamomile extract', 'Panthenol'],
    priceBdt: 420,
    isAvailable: true,
    tags: ['Baby care', 'Fragrance-free', 'Sensitive skin'],
  ),
  Product(
    id: 'p010',
    title: 'Botanical Baby Balm',
    category: 'Baby care',
    description: 'A thick, protective balm for nappy area care. With organic shea butter and zinc. No artificial fragrance.',
    usage: 'Apply a thin layer to clean, dry skin at each change.',
    ingredients: ['Organic shea butter', 'Zinc oxide', 'Beeswax', 'Chamomile oil', 'Vitamin E'],
    priceBdt: 580,
    isAvailable: true,
    tags: ['Baby care', 'Nappy', 'Organic'],
  ),
  Product(
    id: 'p011',
    title: 'Perimenopause Cooling Mist',
    category: 'Cycle care',
    description: 'A refreshing facial mist with rosewater, aloe vera, and peppermint for quick temperature comfort.',
    usage: 'Shake well and mist onto face from 20 cm. Use as needed throughout the day.',
    ingredients: ['Rosa damascena flower water', 'Aloe vera gel', 'Mentha piperita water', 'Glycerin'],
    priceBdt: 490,
    isAvailable: true,
    tags: ['Cycle care', 'Cooling', 'Rosewater'],
  ),
  Product(
    id: 'p012',
    title: 'Iron-Rich Pregnancy Supplement',
    category: 'Pregnancy comfort',
    description: 'A gentle iron supplement with vitamin C to support absorption. Designed to be easy on the digestive system.',
    usage: 'Take one capsule daily with food and water. Consult your healthcare provider before use.',
    ingredients: ['Ferrous bisglycinate', 'Ascorbic acid (Vitamin C)', 'Capsule shell (cellulose)'],
    priceBdt: 950,
    isAvailable: false,
    tags: ['Pregnancy', 'Supplement', 'Coming soon'],
  ),
];
