
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../widgets/platform_utils.dart';
import 'music_picker_page.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  XFile? _image;
  final _picker = ImagePicker();
  bool _isLoading = false;
  String? _selectedTrackID;
  String? _selectedEmoji;
  late TextEditingController _moodTextController;
  bool _isGhostMode = false;
  String _selectedTheme = 'default';

  final List<Map<String, dynamic>> _themes = [
    {'id': 'default', 'name': 'Default', 'colors': [Colors.white, Colors.white]},
    {'id': 'midnight', 'name': 'Midnight', 'colors': [Color(0xFF1A1A2E), Color(0xFF16213E)]},
    {'id': 'sunset', 'name': 'Sunset', 'colors': [Color(0xFFFF512F), Color(0xFFDD2476)]},
    {'id': 'ocean', 'name': 'Ocean', 'colors': [Color(0xFF2193B0), Color(0xFF6DD5ED)]},
    {'id': 'emerald', 'name': 'Emerald', 'colors': [Color(0xFF00B09B), Color(0xFF96C93D)]},
  ];

  final List<String> _emojis = ['😊', '😴', '🔥', '🚀', '🎨', '🍕', '💪', '🎮', '🎧', '✨'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _selectedTrackID = widget.user.spotifyTrackID;
    _selectedEmoji = widget.user.moodEmoji;
     _moodTextController = TextEditingController(text: widget.user.moodText ?? '');
    _isGhostMode = widget.user.isGhostMode;
    _selectedTheme = widget.user.profileTheme;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _moodTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = pickedFile);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.updateProfile(
        name: _nameController.text,
        bio: _bioController.text,
        moodEmoji: _selectedEmoji,
        moodText: _moodTextController.text,
        isGhostMode: _isGhostMode,
        profileTheme: _selectedTheme,
        avatarFile: _image,
      );

      if (success) {
        if (mounted) {
          await Provider.of<AuthProvider>(context, listen: false).refreshUser();
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    } catch (e) {
      print("Update profile error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _image != null
                          ? null // We'll show FileImage via child if needed, or use a workaround for web
                          : (widget.user.avatar != null && widget.user.avatar!.isNotEmpty
                              ? NetworkImage("${ApiService.baseUrl}${widget.user.avatar}")
                              : null),
                      child: _image != null
                          ? ClipOval(child: SizedBox(width: 100, height: 100, child: previewImage(_image!)))
                          : (widget.user.avatar == null || widget.user.avatar!.isEmpty
                              ? const Icon(Icons.camera_alt, size: 40)
                              : null),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _pickImage,
                    child: const Text('Change Profile Photo'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'Bio'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Current Mood', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Show a simple emoji picker or just clear
                          if (_selectedEmoji != null) setState(() => _selectedEmoji = null);
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Center(
                            child: _selectedEmoji != null 
                                ? Text(_selectedEmoji!, style: const TextStyle(fontSize: 24))
                                : const Icon(Icons.add_reaction_outlined, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _moodTextController,
                          decoration: const InputDecoration(
                            hintText: 'What\'s your vibe?',
                            hintStyle: TextStyle(fontSize: 14),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _emojis.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedEmoji = _emojis[index]),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: _selectedEmoji == _emojis[index] ? Colors.blue[100] : Colors.grey[200],
                              child: Text(_emojis[index], style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.music_note, color: Colors.blue),
                    title: const Text('Profile Music'),
                    subtitle: Text(_selectedTrackID != null ? 'Track Selected' : 'Add a theme song to your profile'),
                    trailing: _selectedTrackID != null 
                        ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedTrackID = null)) 
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MusicPickerPage()),
                      );
                      if (result != null && mounted) {
                        setState(() => _selectedTrackID = result);
                      }
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Ghost Mode'),
                    subtitle: const Text('Hide your online status and vibe in the shadows 👻'),
                    value: _isGhostMode,
                    activeColor: Colors.purple,
                    onChanged: (val) {
                      setState(() => _isGhostMode = val);
                    },
                  ),
                  const Divider(),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Profile Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _themes.length,
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final isSelected = _selectedTheme == theme['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTheme = theme['id']),
                            child: Column(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: theme['colors'] as List<Color>,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)] : [],
                                  ),
                                  child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                                ),
                                const SizedBox(height: 4),
                                Text(theme['name'], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
