import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class EvidencePreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> evidenceFiles;
  final int initialIndex;

  const EvidencePreviewScreen({
    super.key,
    required this.evidenceFiles,
    required this.initialIndex,
  });

  @override
  State<EvidencePreviewScreen> createState() => _EvidencePreviewScreenState();
}

class _EvidencePreviewScreenState extends State<EvidencePreviewScreen> {
  late int _currentIndex;
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initPreview();

    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _audioDuration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _audioPosition = p);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _audioPosition = Duration.zero;
      });
    });
  }

  void _initPreview() {
    _disposeControllers();
    final item = widget.evidenceFiles[_currentIndex];
    final type = item['type'] as String;
    final file = item['file'] as File;

    if (type == 'video') {
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() => _videoInitialized = true);
        });
    }
  }

  void _disposeControllers() {
    _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;
    _audioPlayer.stop();
    _isPlaying = false;
    _audioPosition = Duration.zero;
    _audioDuration = Duration.zero;
  }

  void _goTo(int index) {
    _disposeControllers();
    setState(() => _currentIndex = index);
    _initPreview();
  }

  Future<void> _toggleAudio() async {
    final file = widget.evidenceFiles[_currentIndex]['file'] as File;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_audioPosition == Duration.zero) {
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        await _audioPlayer.resume();
      }
    }
  }

  Future<void> _toggleVideo() async {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }
    setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _disposeControllers();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.evidenceFiles[_currentIndex];
    final type = item['type'] as String;
    final file = item['file'] as File;
    final total = widget.evidenceFiles.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / $total  •  ${type[0].toUpperCase()}${type.substring(1)}',
          style: const TextStyle(fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // MAIN PREVIEW AREA
          Expanded(
            child: type == 'image'
                ? _buildImagePreview(file)
                : type == 'video'
                    ? _buildVideoPreview()
                    : _buildAudioPreview(file),
          ),

          // THUMBNAIL STRIP at bottom
          if (total > 1)
            Container(
              height: 70,
              color: Colors.black87,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                itemCount: total,
                itemBuilder: (context, index) {
                  final thumb = widget.evidenceFiles[index];
                  final thumbType = thumb['type'] as String;
                  final thumbFile = thumb['file'] as File;
                  final thumbImg = thumb['thumbnail'] as File?;
                  final isSelected = index == _currentIndex;

                  return GestureDetector(
                    onTap: () => _goTo(index),
                    child: Container(
                      width: 54,
                      height: 54,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A3A5C)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: thumbType == 'image'
                            ? Image.file(thumbFile,
                                fit: BoxFit.cover)
                            : thumbType == 'video' && thumbImg != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(thumbImg,
                                          fit: BoxFit.cover),
                                      const Center(
                                        child: Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white,
                                            size: 20),
                                      ),
                                    ],
                                  )
                                : Container(
                                    color: const Color(0xFF1A3A5C),
                                    child: Icon(
                                      thumbType == 'audio'
                                          ? Icons.audiotrack
                                          : Icons.videocam,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File file) {
    return InteractiveViewer(
      child: Center(
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (!_videoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: _toggleVideo,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          // Play/Pause overlay
          AnimatedOpacity(
            opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow,
                  color: Colors.white, size: 40),
            ),
          ),
          // Progress bar at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF1A3A5C),
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(File file) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A3A5C).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.graphic_eq : Icons.audiotrack,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Audio Recording',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              file.path.split('/').last,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Progress slider
            Slider(
              value: _audioPosition.inSeconds.toDouble(),
              min: 0,
              max: _audioDuration.inSeconds.toDouble() > 0
                  ? _audioDuration.inSeconds.toDouble()
                  : 1,
              activeColor: const Color(0xFF1A3A5C),
              inactiveColor: Colors.white24,
              onChanged: (value) async {
                await _audioPlayer
                    .seek(Duration(seconds: value.toInt()));
              },
            ),

            // Duration labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_audioPosition),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_audioDuration),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Play/Pause button
            GestureDetector(
              onTap: _toggleAudio,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A3A5C).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}