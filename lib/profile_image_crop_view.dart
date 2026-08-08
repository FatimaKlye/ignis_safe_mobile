part of 'profile.dart';

class ProfileImageCropPage extends StatefulWidget {
  const ProfileImageCropPage({
    super.key,
    required this.imageBytes,
    required this.isTl,
  });

  final Uint8List imageBytes;
  final bool isTl;

  @override
  State<ProfileImageCropPage> createState() => _ProfileImageCropPageState();
}

class _ProfileImageCropPageState extends State<ProfileImageCropPage> {
  static const Color _brandRed = Color(0xFFB11217);
  static const double _maxZoom = 4;
  static const int _outputSize = 640;

  ui.Image? _image;
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  double _zoom = 1;
  Offset _offset = Offset.zero;
  double _cropSize = 0;
  double _baseScale = 1;

  double _gestureStartZoom = 1;
  Offset _gestureStartOffset = Offset.zero;
  Offset _gestureStartFocal = Offset.zero;

  String _txt(String en, String tl) => widget.isTl ? tl : en;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      codec.dispose();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _image = frame.image;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Offset _clampOffset(Offset candidate, double zoom) {
    final image = _image;
    if (image == null || _cropSize <= 0) return Offset.zero;

    final renderedWidth = image.width * _baseScale * zoom;
    final renderedHeight = image.height * _baseScale * zoom;
    final maxX = ((renderedWidth - _cropSize) / 2).clamp(0.0, double.infinity);
    final maxY = ((renderedHeight - _cropSize) / 2).clamp(0.0, double.infinity);

    return Offset(
      candidate.dx.clamp(-maxX, maxX).toDouble(),
      candidate.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  void _resetCrop() {
    setState(() {
      _zoom = 1;
      _offset = Offset.zero;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartZoom = _zoom;
    _gestureStartOffset = _offset;
    _gestureStartFocal = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final nextZoom = (_gestureStartZoom * details.scale)
        .clamp(1.0, _maxZoom)
        .toDouble();
    final scaleChange = nextZoom / _gestureStartZoom;
    final center = Offset(_cropSize / 2, _cropSize / 2);
    final focalFromCenter = _gestureStartFocal - center;
    final focalDelta = details.localFocalPoint - _gestureStartFocal;
    final nextOffset =
        (_gestureStartOffset - focalFromCenter) * scaleChange +
        focalFromCenter +
        focalDelta;

    setState(() {
      _zoom = nextZoom;
      _offset = _clampOffset(nextOffset, nextZoom);
    });
  }

  void _setZoom(double value) {
    setState(() {
      _zoom = value;
      _offset = _clampOffset(_offset, value);
    });
  }

  Future<void> _usePhoto() async {
    final image = _image;
    if (image == null || _cropSize <= 0 || _saving) return;

    setState(() => _saving = true);

    try {
      final renderScale = _baseScale * _zoom;
      final renderedWidth = image.width * renderScale;
      final renderedHeight = image.height * renderScale;
      final imageLeft = (_cropSize - renderedWidth) / 2 + _offset.dx;
      final imageTop = (_cropSize - renderedHeight) / 2 + _offset.dy;
      final sourceSize = _cropSize / renderScale;
      final sourceLeft = (-imageLeft / renderScale).clamp(
        0.0,
        image.width - sourceSize,
      );
      final sourceTop = (-imageTop / renderScale).clamp(
        0.0,
        image.height - sourceSize,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(
          sourceLeft.toDouble(),
          sourceTop.toDouble(),
          sourceSize,
          sourceSize,
        ),
        Rect.fromLTWH(0, 0, _outputSize.toDouble(), _outputSize.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );

      final outputImage = await recorder.endRecording().toImage(
        _outputSize,
        _outputSize,
      );
      final byteData = await outputImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      outputImage.dispose();

      if (!mounted) return;
      if (byteData == null) throw StateError('Could not encode cropped image.');

      Navigator.of(context).pop(byteData.buffer.asUint8List());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _txt(
              'Could not prepare this photo. Please try another image.',
              'Hindi maihanda ang larawang ito. Subukan ang ibang larawan.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171113),
      appBar: AppBar(
        backgroundColor: const Color(0xFF171113),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _txt('Adjust profile photo', 'Ayusin ang profile photo'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _resetCrop,
            child: Text(
              _txt('Reset', 'I-reset'),
              style: const TextStyle(
                color: Color(0xFFFFC7C4),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints.biggest;
                  final widthLimit = available.width - 40;
                  final heightLimit = available.height - 50;
                  final size =
                      (widthLimit < heightLimit ? widthLimit : heightLimit)
                          .clamp(140.0, double.infinity)
                          .toDouble();

                  if (_image != null && size != _cropSize) {
                    _cropSize = size;
                    final widthScale = size / _image!.width;
                    final heightScale = size / _image!.height;
                    _baseScale = widthScale > heightScale
                        ? widthScale
                        : heightScale;
                    _offset = _clampOffset(_offset, _zoom);
                  }

                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: size + 10,
                          height: size + 10,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.82),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _brandRed.withValues(alpha: 0.35),
                                blurRadius: 32,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: ColoredBox(
                              color: const Color(0xFF2B2325),
                              child: _buildCropViewport(size),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            _txt(
                              'Drag to position • Pinch or use the slider to zoom',
                              'I-drag para ipuwesto • I-pinch o gamitin ang slider para mag-zoom',
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF21191B),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_size_select_small_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 1,
                          max: _maxZoom,
                          activeColor: _brandRed,
                          inactiveColor: Colors.white24,
                          onChanged: _image == null || _saving
                              ? null
                              : _setZoom,
                        ),
                      ),
                      const Icon(
                        Icons.photo_size_select_large_rounded,
                        color: Colors.white70,
                        size: 23,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _image == null || _saving ? null : _usePhoto,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _saving
                            ? _txt('Preparing...', 'Inihahanda...')
                            : _txt(
                                'Use this photo',
                                'Gamitin ang larawang ito',
                              ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropViewport(double size) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_failed || _image == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _txt(
              'This image could not be opened.',
              'Hindi mabuksan ang larawang ito.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final image = _image!;
    final width = image.width * _baseScale;
    final height = image.height * _baseScale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _saving ? null : _onScaleStart,
      onScaleUpdate: _saving ? null : _onScaleUpdate,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Transform.translate(
              offset: _offset,
              child: Transform.scale(
                scale: _zoom,
                child: RawImage(
                  image: image,
                  width: width,
                  height: height,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
