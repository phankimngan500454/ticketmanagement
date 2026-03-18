class Category {
  final int categoryId;
  final String categoryName;

  const Category({required this.categoryId, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        categoryId:   (json['categoryID'] ?? json['CategoryID']) as int? ?? 0,
        categoryName: (json['categoryName'] ?? json['CategoryName']) as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'CategoryID': categoryId, 'CategoryName': categoryName};
}
