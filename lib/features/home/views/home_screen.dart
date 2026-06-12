import 'package:flutter/material.dart';
import '../../auth/models/user_profile.dart';
import '../../admin_dashboard/views/admin_dashboard.dart';
import '../../worker_feed/views/worker_feed.dart';

class HomeScreen extends StatelessWidget {
  final UserProfile userProfile;

  const HomeScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    if (userProfile.role == 'admin') {
      return AdminDashboard(userProfile: userProfile);
    }
    return WorkerFeed(userProfile: userProfile);
  }
}
