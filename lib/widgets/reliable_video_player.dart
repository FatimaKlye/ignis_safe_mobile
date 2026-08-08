import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReliableVideoPlayer extends StatefulWidget {
  const ReliableVideoPlayer({
    super.key,
    required this.source,
    this.loadingText = 'Loading video...',
    this.errorText = 'Video could not be loaded.',
    this.looping = false,
  });

  final String source;
  final String loadingText;
  final String errorText;
  final bool looping;

  @override
  State<ReliableVideoPlayer> createState() => _ReliableVideoPlayerState();
}

class _ReliableVideoPlayerState extends State<ReliableVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  Object? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReliableVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.trim() != widget.source.trim() ||
        oldWidget.looping != widget.looping) {
      _load();
    }
  }

  bool _isNetworkSource(String source) {
    final scheme = Uri.tryParse(source)?.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https';
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    final previous = _controller;
    _controller = null;
    await previous?.dispose();

    if (!mounted || generation != _loadGeneration) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final source = widget.source.trim();
    if (source.isEmpty) {
      setState(() {
        _loading = false;
        _error = ArgumentError('The video source is empty.');
      });
      return;
    }

    VideoPlayerController? controller;
    try {
      controller = _isNetworkSource(source)
          ? VideoPlayerController.networkUrl(Uri.parse(source))
          : VideoPlayerController.asset(source);
      await controller.initialize();
      await controller.setLooping(widget.looping);

      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (error) {
      await controller?.dispose();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      if (controller.value.position >= controller.value.duration) {
        await controller.seekTo(Duration.zero);
      }
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _loadGeneration++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_loading) {
      return ColoredBox(
        color: const Color(0xFF111827),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 10),
              Text(widget.loadingText, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }
    if (_error != null || controller == null || !controller.value.isInitialized) {
      return ColoredBox(
        color: const Color(0xFF111827),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 34),
                const SizedBox(height: 8),
                Text(widget.errorText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayback,
      child: ColoredBox(
        color: const Color(0xFF111827),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio > 0 ? controller.value.aspectRatio : 16 / 9,
                child: VideoPlayer(controller),
              ),
            ),
            if (!controller.value.isPlaying)
              const Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.black54,
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(controller, allowScrubbing: true, padding: EdgeInsets.zero),
            ),
          ],
        ),
      ),
    );
  }
}
