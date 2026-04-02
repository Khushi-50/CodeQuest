class UserModel {
  final String username;
  final String email;
  final int xp;
  final String languagePreference; // Add this
  final List<UserProgress> progress;

  UserModel({
    required this.username,
    required this.email,
    required this.xp,
    required this.languagePreference,
    required this.progress,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      xp: json['xp'] ?? 0,
      // Fallback to 'C' if the field is missing from the API response
      languagePreference: json['languagePreference'] ?? json['language'] ?? 'C',
      progress: (json['progress'] as List? ?? [])
          .map((p) => UserProgress.fromJson(p))
          .toList(),
    );
  }
}
// 1. THE CORE USER MODEL
// class UserModel {
//   final String id;
//   final String username;
//   final String email;
//   final List<String> selectedCourse;
//   final String joiningtime;

//   UserModel({
//     required this.id,
//     required this.username,
//     required this.email,
//     required this.selectedCourse,
//     required this.joiningtime,
//   });

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
//       username: json['username'] ?? '',
//       email: json['email'] ?? '',
//       selectedCourse: (json['selectedCourse'] as List<dynamic>? ?? [])
//           .map((e) => e.toString())
//           .toList(),
//       joiningtime: json['joiningtime'] ?? '',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'username': username,
//       'email': email,
//       'selectedCourse': selectedCourse,
//       'joiningtime': joiningtime,
//     };
//   }
// }

// 2. AUTH RESPONSE MODELS (For Login/Signup)
class LoginResponseModel {
  final String message;
  final String token;
  final UserModel user;

  LoginResponseModel({
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class UserProgress {
  final String questionId; // Maps to Mongoose's question_id
  final String status; // 'unlocked', 'completed', 'failed'

  UserProgress({required this.questionId, required this.status});

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      // Handles both potential backend naming conventions safely
      questionId:
          json['question_id']?.toString() ??
          json['subtopicId']?.toString() ??
          '',
      status: json['status'] ?? 'locked',
    );
  }
}
