class JobModel {
  final String id;
  final String designation;
  final String company;
  final String experience;
  final String location;
  final String description;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;

  JobModel({
    required this.id,
    required this.designation,
    required this.company,
    required this.experience,
    required this.location,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
  });

  // 🔁 Firestore → Model
  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id,
      designation: map['designation'] ?? '',
      company: map['company'] ?? '',
      experience: map['experience'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Alumni',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // 🔁 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'designation': designation,
      'company': company,
      'experience': experience,
      'location': location,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt,
    };
  }
}
