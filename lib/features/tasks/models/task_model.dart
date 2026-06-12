import '../../auth/models/user_profile.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final String status;
  final DateTime? scheduledFor;
  final String createdBy;
  final String? completedBy;
  final DateTime? completedAt;
  final UserProfile? completedByUser;
  final String? folderId;
  String? folderName;
  String? completedByName;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.scheduledFor,
    required this.createdBy,
    this.completedBy,
    this.completedAt,
    this.completedByUser,
    this.folderId,
    this.folderName,
    this.completedByName,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      scheduledFor: json['scheduled_for'] != null 
          ? DateTime.parse(json['scheduled_for'].toString()) 
          : null,
      createdBy: json['created_by']?.toString() ?? '',
      completedBy: json['completed_by']?.toString(),
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'].toString()) 
          : null,
      completedByUser: json['profiles'] != null 
          ? UserProfile.fromJson(json['profiles']) 
          : null,
      folderId: json['folder_id']?.toString(),
    );
  }
}
