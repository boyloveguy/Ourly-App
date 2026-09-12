class AppUser {
  final String uid;
  final String email;
  final String nickname;
  final String? activeCoupleId;
  final String? avatar;
  final String? birthday;
  final String? gender;
  final String? datingStartDate;

  AppUser({
    required this.uid,
    required this.email,
    required this.nickname,
    this.activeCoupleId,
    this.avatar,
    this.birthday,
    this.gender,
    this.datingStartDate,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      activeCoupleId: json['activeCoupleId'] as String?,
      avatar: json['avatar'] as String?,
      birthday: json['birthday'] as String?,
      gender: json['gender'] as String?,
      datingStartDate: json['datingStartDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'nickname': nickname,
    'activeCoupleId': activeCoupleId,
    'avatar': avatar,
    'birthday': birthday,
    'gender': gender,
    'datingStartDate': datingStartDate,
  };
}
