import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';


class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuestProvider>().fetchQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
        centerTitle: true,
      ),
      body: Consumer<QuestProvider>(
        builder: (context, questProvider, _) {
          if (questProvider.isLoading && questProvider.userQuests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (questProvider.userQuests.isEmpty) {
            return const Center(child: Text("No quests available right now. Check back later!"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: questProvider.userQuests.length,
            itemBuilder: (context, index) {
              final userQuest = questProvider.userQuests[index];
              final quest = userQuest.quest;
              if (quest == null) return const SizedBox.shrink();

              final progress = userQuest.progress / quest.targetCount;
              final isReadyToClaim = userQuest.progress >= quest.targetCount && !userQuest.isCompleted;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quest.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(quest.description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${quest.points} pts',
                              style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress > 1 ? 1 : progress,
                                backgroundColor: Colors.grey[200],
                                color: userQuest.isCompleted ? Colors.green : Colors.blue,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${userQuest.progress}/${quest.targetCount}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isReadyToClaim
                              ? () async {
                                  final success = await questProvider.claimQuest(quest.id);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Claimed ${quest.points} points! 🏆')),
                                    );
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: userQuest.isCompleted ? Colors.grey[200] : (isReadyToClaim ? Colors.orange : Colors.blue),
                            foregroundColor: userQuest.isCompleted ? Colors.grey[600] : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(userQuest.isCompleted ? 'Completed ✅' : (isReadyToClaim ? 'Claim Reward!' : 'Stay Active')),
                        ),
                      ),
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
