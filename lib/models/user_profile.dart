class UserProfile {
  final String id;
  final String name;
  final String status;
  final String address;
  final String contact;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.status,
    required this.address,
    required this.contact,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'address': address,
      'contact': contact,
      'photo_url': photoUrl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? '',
      address: map['address'] ?? '',
      contact: map['contact'] ?? '',
      photoUrl: map['photo_url'],
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? status,
    String? address,
    String? contact,
    String? photoUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
