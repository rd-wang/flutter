class FeatureEntity {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? asset;
  final Function onTap;

  FeatureEntity({
    required this.title,
    required this.onTap,
    this.description,
    this.asset,
    this.imageUrl,
  });
}
