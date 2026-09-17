import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../data/repositories/karatflow_api_repository.dart';

class CommonRemoteImage extends StatefulWidget {
  const CommonRemoteImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon,
    this.fallbackWidget,
    this.heroTag,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData? fallbackIcon;
  final Widget? fallbackWidget;
  final String? heroTag;

  @override
  State<CommonRemoteImage> createState() => _CommonRemoteImageState();
}

class _CommonRemoteImageState extends State<CommonRemoteImage> {
  static final Map<String, Uint8List> _bytesCache = {};
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant CommonRemoteImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final rawUrl = widget.imageUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    final lower = rawUrl.toLowerCase();
    // Non-image 3D CAD/data files or browser-memory blob: URLs should directly show fallback
    if (lower.startsWith('blob:') ||
        lower.endsWith('.stl') ||
        lower.endsWith('.xtl') ||
        lower.endsWith('.obj') ||
        lower.endsWith('.ply') ||
        lower.endsWith('.bom') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.pdf')) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    if (_bytesCache.containsKey(rawUrl)) {
      if (mounted) {
        setState(() {
          _imageBytes = _bytesCache[rawUrl];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // 1. Base64 Data URI
    if (rawUrl.startsWith('data:image/')) {
      try {
        final commaIdx = rawUrl.indexOf(',');
        if (commaIdx != -1) {
          final bytes = base64Decode(rawUrl.substring(commaIdx + 1));
          _bytesCache[rawUrl] = bytes;
          if (mounted) {
            setState(() {
              _imageBytes = bytes;
              _isLoading = false;
              _hasError = false;
            });
          }
          return;
        }
      } catch (_) {}
    }

    // 2. Local File on device
    try {
      final file = File(rawUrl);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          _bytesCache[rawUrl] = bytes;
          if (mounted) {
            setState(() {
              _imageBytes = bytes;
              _isLoading = false;
              _hasError = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // 3. Flutter Asset
    if (rawUrl.startsWith('assets/') || rawUrl.startsWith('asset:')) {
      try {
        final clean = rawUrl.replaceFirst('asset:', '');
        final data = await rootBundle.load(clean);
        final bytes = data.buffer.asUint8List();
        if (bytes.isNotEmpty) {
          _bytesCache[rawUrl] = bytes;
          if (mounted) {
            setState(() {
              _imageBytes = bytes;
              _isLoading = false;
              _hasError = false;
            });
          }
          return;
        }
      } catch (_) {}
    }

    // 4. Download from API or storage
    try {
      Uint8List? bytes;
      try {
        bytes = await KaratFlowApiRepository().downloadStoredFile(rawUrl);
      } catch (_) {
        // Continue to the next image fallback.
      }

      // 5. Fallback: Direct HTTP download if downloadStoredFile failed
      if ((bytes == null || bytes.isEmpty) &&
          (rawUrl.startsWith('http://') ||
              rawUrl.startsWith('https://') ||
              rawUrl.startsWith('/') ||
              rawUrl.startsWith('api/') ||
              rawUrl.startsWith('storage/'))) {
        try {
          bytes = await KaratFlowApiRepository().apiClient.getBytes(rawUrl);
        } catch (_) {
          // Continue to the next image fallback.
        }
      }

      if (bytes != null && bytes.isNotEmpty) {
        _bytesCache[rawUrl] = bytes;
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        throw const FormatException('Empty image payload received.');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageBytes = null;
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildFallback() {
    if (widget.fallbackWidget != null) {
      return widget.fallbackWidget!;
    }
    return Center(
      child: Icon(
        widget.fallbackIcon ?? Icons.diamond_outlined,
        size: 32,
        color: AppColors.muted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ??
        BorderRadius.circular(AppDimensions.radiusMedium);

    Widget content;
    if (_isLoading) {
      content = Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.goldLight.withValues(alpha: 0.2),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold,
            ),
          ),
        ),
      );
    } else if (_hasError || _imageBytes == null || _imageBytes!.isEmpty) {
      content = Container(
        width: widget.width,
        height: widget.height,
        color: AppColors.canvas,
        child: _buildFallback(),
      );
    } else {
      content = Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.canvas,
          child: _buildFallback(),
        ),
      );
    }

    if (widget.heroTag != null && widget.heroTag!.isNotEmpty) {
      content = Hero(tag: widget.heroTag!, child: content);
    }

    return ClipRRect(borderRadius: radius, child: content);
  }
}
