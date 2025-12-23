import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';

class FlashTicker extends StatefulWidget {
  const FlashTicker({super.key});

  @override
  State<FlashTicker> createState() => _FlashTickerState();
}

class _FlashTickerState extends State<FlashTicker> {
  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _events = [];
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    final wsUrl = ApiService.wsUrl;
    _channel = WebSocketChannel.connect(Uri.parse("$wsUrl/ws/flash"));
    
    _channel!.stream.listen((message) {
      if (mounted) {
        setState(() {
          _events.insert(0, jsonDecode(message));
          if (_events.length > 10) _events.removeLast();
        });
      }
    }, onError: (e) {
      print("Flash WebSocket Error: $e");
      Future.delayed(const Duration(seconds: 5), _connect);
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _scrollController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_events.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.blue,
            child: const Center(
              child: Text(
                "FLASH",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return _buildEventItem(event);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    IconData icon;
    switch (event['type']) {
      case 'post': icon = Icons.add_box_outlined; break;
      case 'follow': icon = Icons.person_add_outlined; break;
      default: icon = Icons.bolt;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.blue),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              children: [
                TextSpan(text: event['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: " ${event['type'] == 'post' ? 'posted' : 'is growing'}! "),
                TextSpan(text: event['title'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
