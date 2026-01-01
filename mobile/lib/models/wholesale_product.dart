class WholesaleProduct {
  final String id;
  final String name;
  final double wholesalePrice;
  final String image;
  final String supplier;
  final String description;

  WholesaleProduct({
    required this.id,
    required this.name,
    required this.wholesalePrice,
    required this.image,
    required this.supplier,
    this.description = '',
  });

  factory WholesaleProduct.fromJson(Map<String, dynamic> json) {
    return WholesaleProduct(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      wholesalePrice: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      image: json['imageUrl'] ?? '',
      supplier: json['supplierName'] ?? 'Rana Grosir',
      description: json['description'] ?? '',
    );
  }
}
