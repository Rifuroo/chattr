import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SpotifyPlayer extends StatefulWidget {
  final String trackId;
  final bool isSmall;

  const SpotifyPlayer({
    super.key,
    required this.trackId,
    this.isSmall = false,
  });

  @override
  State<SpotifyPlayer> createState() => _SpotifyPlayerState();
}

class _SpotifyPlayerState extends State<SpotifyPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Map<String, dynamic>? _trackData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrackData();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _fetchTrackData() async {
    try {
      final response = await ApiService.get('/spotify/track/${widget.trackId}');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _trackData = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching Spotify track: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_trackData == null || _trackData!['preview_url'] == null) return;

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(_trackData!['preview_url']));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.isSmall 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : const Center(child: CircularProgressIndicator());
    }

    if (_trackData == null) {
      return const SizedBox.shrink();
    }

    final String albumArt = (_trackData!['album']['images'] as List).isNotEmpty 
        ? _trackData!['album']['images'][0]['url'] 
        : "";
    final String trackName = _trackData!['name'] ?? "Unknown";
    final String artistName = (_trackData!['artists'] as List).isNotEmpty 
        ? _trackData!['artists'][0]['name'] 
        : "Unknown";

    if (widget.isSmall) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _togglePlay,
              child: Icon(
                _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "$trackName - $artistName",
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: albumArt,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, e) => const Icon(Icons.music_note),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trackName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      artistName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  color: Colors.green,
                  size: 32,
                ),
                onPressed: _togglePlay,
              ),
            ],
          ),
          if (_playerState == PlayerState.playing || _position > Duration.zero) ...[
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: Colors.green,
                inactiveTrackColor: Colors.grey[200],
                thumbColor: Colors.green,
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 30000.0,
                onChanged: (value) async {
                  await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
