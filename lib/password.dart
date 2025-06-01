class Password {
  final int? id;
  final String purpose;
  final String account;
  final String password;
  final String note;
  final int viewCount;
  final DateTime? lastViewedTime;
  final DateTime? createdTime;
  final bool isFavorite;
  final String category;

  Password({
    this.id,
    required this.purpose,
    required this.account,
    required this.password,
    required this.note,
    this.viewCount = 0,
    this.lastViewedTime,
    this.createdTime,
    this.isFavorite = false,
    this.category = 'other',
  });

  Map<String, dynamic> toMap() {
    return {
      'purpose': purpose,
      'account': account,
      'password': password,
      'note': note,
      'view_count': viewCount,
      'last_viewed_time': lastViewedTime?.toIso8601String(),
      'created_time': createdTime?.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'category': category,
    };
  }

  factory Password.fromMap(Map<String, dynamic> map) {
    return Password(
      id: map['id'],
      purpose: map['purpose'],
      account: map['account'],
      password: map['password'],
      note: map['note'],
      viewCount: map['view_count'] ?? 0,
      lastViewedTime: map['last_viewed_time'] != null 
          ? DateTime.tryParse(map['last_viewed_time']) 
          : null,
      createdTime: map['created_time'] != null 
          ? DateTime.tryParse(map['created_time']) 
          : null,
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      category: map['category'] ?? 'other',
    );
  }
}