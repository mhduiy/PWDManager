class Password {
  final int? id;
  final String purpose;
  final String account;
  final String password;
  final String note;

  Password({
    this.id,
    required this.purpose,
    required this.account,
    required this.password,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'purpose': purpose,
      'account': account,
      'password': password,
      'note': note,
    };
  }

  factory Password.fromMap(Map<String, dynamic> map) {
    return Password(
      id: map['id'],
      purpose: map['purpose'],
      account: map['account'],
      password: map['password'],
      note: map['note'],
    );
  }
}