import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../pages/profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FollowersPage extends StatefulWidget {
  final int userId;
  final bool isFollowers; // true for followers, false for following

  const FollowersPage({super.key, required this.userId, required this.isFollowers});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final endpoint = widget.isFollowers 
          ? '/users/${widget.userId}/followers' 
          : '/users/${widget.userId}/following';
      
      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data.map((json) => User.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFollowers ? 'Followers' : 'Following'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text('No users found'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                            ? CachedNetworkImageProvider("${ApiService.baseUrl}${user.avatar}")
                            : null,
                        child: (user.avatar == null || user.avatar!.isEmpty)
                            ? Text(user.username[0].toUpperCase())
                            : null,
                      ),
                      title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(user.name),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfilePage(userId: user.id)),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
