import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/privacy_provider.dart';
import '../widgets/user_avatar.dart';

class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({super.key});

  @override
  State<FollowRequestsPage> createState() => _FollowRequestsPageState();
}

class _FollowRequestsPageState extends State<FollowRequestsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PrivacyProvider>(context, listen: false).fetchFollowRequests());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Requests'),
      ),
      body: Consumer<PrivacyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.followRequests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending follow requests', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.followRequests.length,
            itemBuilder: (context, index) {
              final request = provider.followRequests[index];
              final follower = request.follower!;

              return ListTile(
                leading: UserAvatar(imageUrl: follower.avatar, radius: 20),
                title: Text(follower.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(follower.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => provider.respondToRequest(request.id, 'accept'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => provider.respondToRequest(request.id, 'reject'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
