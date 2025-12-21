import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MusicPickerPage extends StatefulWidget {
  const MusicPickerPage({super.key});

  @override
  State<MusicPickerPage> createState() => _MusicPickerPageState();
}

class _MusicPickerPageState extends State<MusicPickerPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results = [];
  bool _isSearching = false;

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    
    setState(() => _isSearching = true);
    
    try {
      final response = await ApiService.get('/spotify/search?q=$query');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _results = jsonDecode(response.body);
            _isSearching = false;
          });
        }
      } else {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      print("Spotify search error: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Music', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for songs or artists...',
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                fillColor: Colors.grey[100],
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _search,
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _results.isEmpty && _searchController.text.isNotEmpty
              ? const Center(child: Text('No tracks found', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final track = _results[index];
                    final String albumArt = (track['album']['images'] as List).isNotEmpty 
                        ? track['album']['images'][0]['url'] 
                        : "";
                    final String artists = (track['artists'] as List)
                        .map((a) => a['name'])
                        .join(", ");

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: albumArt.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: albumArt,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                                  )
                                : Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.green,
                                    child: const Icon(Icons.music_note, color: Colors.white),
                                  ),
                          ),
                          title: Text(track['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(artists, style: TextStyle(color: Colors.grey[600])),
                          trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                          onTap: () {
                            Navigator.pop(context, track['id']);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
