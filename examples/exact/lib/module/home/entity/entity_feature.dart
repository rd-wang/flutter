class FeatureEntity {
  final String title;
  final String description;
  final String imageUrl;
  final Function onTap;

  FeatureEntity({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });
}
