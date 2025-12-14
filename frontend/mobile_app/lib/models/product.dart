class Product {
  final String id;
  final String name;
  final String producerID;
  final String manufactureDate;
  final String certHash;
  final String status;

  Product({
    required this.id,
    required this.name,
    required this.producerID,
    required this.manufactureDate,
    required this.certHash,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      producerID: json['producer_id'] ?? '',
      manufactureDate: json['manufacture_date'] ?? '',
      certHash: json['cert_hash'] ?? '',
      status: json['status'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'producer_id': producerID,
      'manufacture_date': manufactureDate,
      'cert_hash': certHash,
      'status': status,
    };
  }
}
