class Photo {
  final String photo_id;
  final String photo_url;
  final DateTime date_added;

  Photo({
    required this.photo_id,
    required this.photo_url, 
    required this.date_added,
    });

  Photo.fromJson(Map<String, dynamic> json)
      : photo_id = json['photo_id'] as String,
        photo_url = json['photo_url'] as String,
        date_added = json['date_added'] as DateTime;

  Photo copyWith({
    String? photo_id,
    String? photo_url,
    DateTime? date_added,
  }) {
    return Photo(
      photo_id: photo_id ?? this.photo_id,
      photo_url: photo_url ?? this.photo_url,
      date_added: date_added ?? this.date_added,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_id': photo_id,
      'photo_url': photo_url,
      'date_added': date_added,
    };
  }
}
