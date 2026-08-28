class WhatsNewSlide {
  final bool featured;
  final String tag;
  final String title;
  final String description;
  final String icon;

  const WhatsNewSlide({
    required this.featured,
    required this.tag,
    required this.title,
    required this.description,
    required this.icon,
  });

  factory WhatsNewSlide.fromJson(Map<String, dynamic> j) => WhatsNewSlide(
        featured: j['featured'] as bool? ?? false,
        tag: j['tag'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        icon: j['icon'] as String? ?? '',
      );
}

class WhatsNewData {
  final String id;
  final String title;
  final String subtitle;
  final List<WhatsNewSlide> slides;

  const WhatsNewData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.slides,
  });
}
