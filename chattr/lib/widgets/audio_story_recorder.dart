import 'dart:io';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AudioStoryRecorder extends StatefulWidget {
  final VoidCallback onStoryCreated;
  const AudioStoryRecorder({super.key, required this.onStoryCreated});

  @override
  State<AudioStoryRecorder> createState() => _AudioStoryRecorderState();
}

class _AudioStoryRecorderState extends State<AudioStoryRecorder> {
  late AudioRecorder _recorder;
  bool _isRecording = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _path = '${dir.path}/moment_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(const RecordConfig(), path: _path!);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      print("Start recording error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        _uploadAudio(path);
      }
    } catch (e) {
      print("Stop recording error: $e");
    }
  }

  Future<void> _uploadAudio(String path) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vibing your moment to Chattr...')));
    
    final file = File(path);
    final stats = await file.stat();
    if (stats.size == 0) return;

    // We can use a custom Multipart request for stories here
    // We can use a custom Multipart request for stories here

    final result = await ApiService.postMultipart(
      '/stories',
      {'is_audio': 'true'},
      [XFile(path)],
      fieldName: 'media',
    );

    if (result.statusCode == 201) {
      widget.onStoryCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Share a Moment",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            _isRecording ? "Recording your vibe..." : "Press and hold to record",
            style: TextStyle(color: _isRecording ? Colors.red : Colors.grey),
          ),
          const SizedBox(height: 30),
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            onLongPressEnd: (_) => _stopRecording(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _isRecording ? 100 : 80,
              height: _isRecording ? 100 : 80,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            "Moments vanish in 24 hours ⏳",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
