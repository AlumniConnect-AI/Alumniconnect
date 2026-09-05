class EventModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String location;
  final String ownerId;
  final String ownerName;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.ownerId,
    required this.ownerName,
    required this.createdAt,
  });

  // Firestore → Model
  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      location: map['location'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Alumni',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  // Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'createdAt': createdAt,
    };
  }
}
