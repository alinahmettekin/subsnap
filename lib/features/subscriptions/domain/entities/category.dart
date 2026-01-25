/// Kategori modeli (DB'den gelir)
class Category {
  final String id;
  final String name;

  const Category({
    required this.id,
    required this.name,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
    );
  }
}
