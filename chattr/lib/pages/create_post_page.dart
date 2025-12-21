import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../providers/post_provider.dart';
import '../providers/mention_provider.dart';
import '../widgets/platform_utils.dart';
import '../widgets/mention_tag_overlay.dart';
import 'music_picker_page.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _contentController = TextEditingController();
  final _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  
  List<XFile> _mediaFiles = [];
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isAddingPoll = false;
  String? _selectedTrackID;
  bool _isFlash = false;
  int _expiresIn = 24; // hours
  bool _isCollaborativePoll = false;
  bool _isGeneratingCaption = false;

  // Mentions
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String _mentionQuery = "";

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_onContentChanged);
  }

  void _onContentChanged() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    if (selection.baseOffset <= 0) {
      _hideMentionOverlay();
      return;
    }

    // Look for @ before cursor
    final beforeCursor = text.substring(0, selection.baseOffset);
    final lastAt = beforeCursor.lastIndexOf('@');
    
    if (lastAt >= 0) {
      // Check if it's the start of word
      if (lastAt == 0 || beforeCursor[lastAt - 1] == ' ' || beforeCursor[lastAt - 1] == '\n') {
        _mentionQuery = beforeCursor.substring(lastAt + 1);
        if (!_mentionQuery.contains(' ')) {
          _showMentionOverlay();
          context.read<MentionProvider>().searchUsers(_mentionQuery);
          return;
        }
      }
    }
    
    _hideMentionOverlay();
  }

  void _showMentionOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 250,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 45), // Position below the cursor line roughly
          child: MentionTagOverlay(
            onUserSelected: (user) {
              _applyMention(user.username);
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMentionOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    context.read<MentionProvider>().clearSuggestions();
  }

  void _applyMention(String username) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    final beforeCursor = text.substring(0, selection.baseOffset);
    final lastAt = beforeCursor.lastIndexOf('@');
    
    final newText = text.replaceRange(lastAt, selection.baseOffset, "@$username ");
    _contentController.text = newText;
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: lastAt + username.length + 2)
    );
    
    _hideMentionOverlay();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() => _mediaFiles.addAll(pickedFiles));
    }
  }

  Future<void> _pickVideo() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _mediaFiles.add(pickedFile));
    }
  }

  void _removeMedia(int index) {
    setState(() => _mediaFiles.removeAt(index));
  }

  void _addOption() {
    if (_pollOptionControllers.length < 5) {
      setState(() => _pollOptionControllers.add(TextEditingController()));
    }
  }

  void _removeOption(int index) {
    if (_pollOptionControllers.length > 2) {
      setState(() {
        _pollOptionControllers[index].dispose();
        _pollOptionControllers.removeAt(index);
      });
    }
  }

  void _submit() async {
    if (_mediaFiles.isEmpty && _contentController.text.isEmpty && !_isAddingPoll) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add content, media, or a poll')),
      );
      return;
    }

    if (_isAddingPoll) {
      if (_pollQuestionController.text.isEmpty || _pollOptionControllers.any((e) => e.text.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the poll question and all options')),
        );
        return;
      }
    }
    
    setState(() => _isLoading = true);
    
    final List<String>? pollOptions = _isAddingPoll 
        ? _pollOptionControllers.map((e) => e.text).toList() 
        : null;

    final success = await context.read<PostProvider>().createPost(
      _contentController.text,
      _mediaFiles.isEmpty ? null : _mediaFiles,
      pollQuestion: _isAddingPoll ? _pollQuestionController.text : null,
      pollOptions: pollOptions,
      spotifyTrackID: _selectedTrackID,
      isFlash: _isFlash,
      expiresIn: _isFlash ? _expiresIn : null,
      isCollaborative: _isCollaborativePoll,
    );
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create post.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _overlayEntry?.remove();
    _contentController.dispose();
    _pollQuestionController.dispose();
    for (var controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: _isGeneratingCaption 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.auto_awesome, color: Colors.purple),
                            onPressed: _isGeneratingCaption ? null : () async {
                              if (_contentController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Type a keyword for the AI to vibe with!')));
                                return;
                              }
                              setState(() => _isGeneratingCaption = true);
                              final caption = await context.read<PostProvider>().generateAICaption(_contentController.text);
                              setState(() => _isGeneratingCaption = false);
                              if (caption != null) {
                                _contentController.text = caption;
                              }
                            },
                            tooltip: 'Magic Caption UI',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            if (_isAddingPoll) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Poll', style: TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Text('Collaborative', style: TextStyle(fontSize: 12)),
                              Switch(
                                value: _isCollaborativePoll,
                                onChanged: (v) => setState(() => _isCollaborativePoll = v),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => setState(() => _isAddingPoll = false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextField(
                        controller: _pollQuestionController,
                        decoration: const InputDecoration(
                          hintText: 'Ask a question...',
                          border: UnderlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_pollOptionControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pollOptionControllers[index],
                                  decoration: InputDecoration(
                                    hintText: 'Option ${index + 1}',
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_pollOptionControllers.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                  onPressed: () => _removeOption(index),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (_pollOptionControllers.length < 5)
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Option'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_mediaFiles.isNotEmpty)
              Container(
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mediaFiles.length,
                  itemBuilder: (context, index) {
                    final file = _mediaFiles[index];
                    final isVideo = file.name.endsWith('.mp4') || file.name.endsWith('.mov');
                    
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: isVideo 
                              ? Container(color: Colors.black, child: const Icon(Icons.videocam, color: Colors.white, size: 40))
                              : previewImage(file),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _removeMedia(index),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          if (isVideo)
                            const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Photos'),
              onTap: _pickImages,
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.red),
              title: const Text('Videos'),
              onTap: _pickVideo,
            ),
            ListTile(
              leading: const Icon(Icons.poll, color: Colors.blue),
              title: const Text('Poll'),
              onTap: () => setState(() => _isAddingPoll = true),
              enabled: !_isAddingPoll,
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Colors.blue),
              title: Text(_selectedTrackID != null ? 'Music Added' : 'Add Music'),
              trailing: _selectedTrackID != null 
                ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selectedTrackID = null)) 
                : null,
              onTap: () async {
                final trackId = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const MusicPickerPage()),
                );
                if (trackId != null) {
                  setState(() => _selectedTrackID = trackId);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt, color: Colors.amber),
              title: const Text('Flash Post'),
              subtitle: _isFlash ? Text('Expires in $_expiresIn hours') : null,
              trailing: Switch(
                value: _isFlash,
                onChanged: (v) => setState(() => _isFlash = v),
              ),
            ),
            if (_isFlash)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('1h'),
                    Expanded(
                      child: Slider(
                        value: _expiresIn.toDouble(),
                        min: 1,
                        max: 72,
                        divisions: 71,
                        label: '$_expiresIn hours',
                        onChanged: (v) => setState(() => _expiresIn = v.toInt()),
                      ),
                    ),
                    const Text('72h'),
                  ],
                ),
              ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
