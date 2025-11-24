class Gallery {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final int categoryId;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Gallery({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Gallery.fromJson(Map<String, dynamic> json) {
    return Gallery(
      id: json['ID'],
      title: "",
      description: "",
      imageUrl: json['image_url'],
      categoryId: json['category_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['CreatedAt']),
      updatedAt: DateTime.parse(json['UpdatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'category_id': categoryId,
      'user_id': userId,
      'CreatedAt': createdAt.toIso8601String(),
      'UpdatedAt': updatedAt.toIso8601String(),
    };
  }
}