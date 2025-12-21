import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mention_provider.dart';
import '../models/models.dart';

class MentionTagOverlay extends StatelessWidget {
  final Function(User) onUserSelected;

  const MentionTagOverlay({super.key, required this.onUserSelected});

  @override
  Widget build(BuildContext context) {
    return Consumer<MentionProvider>(
      builder: (context, mentionProvider, _) {
        if (mentionProvider.suggestions.isEmpty && !mentionProvider.isLoading) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 200),
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: mentionProvider.isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                  ))
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: mentionProvider.suggestions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = mentionProvider.suggestions[index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                              ? NetworkImage(user.profilePicture!)
                              : null,
                          child: user.profilePicture == null || user.profilePicture!.isEmpty
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        title: Text(
                          user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: user.name.isNotEmpty
                            ? Text(user.name, style: const TextStyle(fontSize: 11))
                            : null,
                        onTap: () => onUserSelected(user),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
