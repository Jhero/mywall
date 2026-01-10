class Gallery {
  final int? id;
  final String? title;
  final String? description;
  final String? imageUrl;
  final int? categoryId;
  final int? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Gallery({
    this.id,
    this.title,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['id'], // bisa null
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'],
      userId: json['user_id'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }
}
