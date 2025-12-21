import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/privacy_provider.dart';

class TellsPage extends StatefulWidget {
  const TellsPage({super.key});

  @override
  State<TellsPage> createState() => _TellsPageState();
}

class _TellsPageState extends State<TellsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PrivacyProvider>(context, listen: false).fetchMyTells());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anonymous Tells'),
      ),
      body: Consumer<PrivacyProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.myTells.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.question_answer_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No anonymous tells yet', style: TextStyle(color: Colors.grey)),
                  Text('Share your profile to get some!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.myTells.length,
            itemBuilder: (context, index) {
              final tell = provider.myTells[index];
              final dateStr = DateFormat('MMM d, h:mm a').format(tell.createdAt);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: tell.isRead ? Colors.grey[100] : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Anonymous Message', 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                          Text(dateStr, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(tell.content, style: const TextStyle(fontSize: 16)),
                      if (!tell.isRead) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => provider.markTellAsRead(tell.id),
                            child: const Text('Mark as Read', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
