import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/story_provider.dart';

class CreateSharedStoryPage extends StatefulWidget {
  const CreateSharedStoryPage({super.key});

  @override
  State<CreateSharedStoryPage> createState() => _CreateSharedStoryPageState();
}

class _CreateSharedStoryPageState extends State<CreateSharedStoryPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  XFile? _selectedCover;
  bool _isLoading = false;

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedCover = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Shared Album"),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: () async {
                if (_titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
                  return;
                }
                setState(() => _isLoading = true);
                final success = await context.read<StoryProvider>().createSharedStory(
                  _titleController.text,
                  _descController.text,
                  _selectedCover,
                );
                setState(() => _isLoading = false);
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: _selectedCover != null
                      ? DecorationImage(image: FileImage(File(_selectedCover!.path)), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedCover == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text("Add Cover Image", style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Album Title",
                hintText: "e.g., Summer Trip 2024",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description (Optional)",
                hintText: "What is this album about?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
