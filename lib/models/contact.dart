class Contact {
  final String? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String category;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.category = 'Umum',
  });

  factory Contact.fromMap(String id, Map<dynamic, dynamic> map) {
    return Contact(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      category: map['category'] ?? 'Umum',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'category': category,
    };
  }
}
