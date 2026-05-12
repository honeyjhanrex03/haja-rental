
class FeedbackModel {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final int rating;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'User',
      comment: json['comment']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'comment': comment,
      'rating': rating,
    };
  }
}
