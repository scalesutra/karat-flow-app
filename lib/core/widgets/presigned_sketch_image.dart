import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../constants/app_colors.dart';
import '../network/api_endpoints.dart';
import 'common_progress_indicator.dart';

/// Ultra-Modern Presigned AWS S3 / Cloudflare R2 & Local File Sketch Image Renderer
class PresignedSketchImage extends StatefulWidget {
  const PresignedSketchImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.loadingLabel,
    this.errorBuilder,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? loadingLabel;
  final Widget Function()? errorBuilder;

  @override
  State<PresignedSketchImage> createState() => _PresignedSketchImageState();
}

class _PresignedSketchImageState extends State<PresignedSketchImage> {
  static final Map<String, String> _urlCache = {};
  static final Map<String, Uint8List> _bytesCache = {};
  String? _resolvedUrl;
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void didUpdateWidget(PresignedSketchImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadUrl();
    }
  }

  Future<void> _loadUrl() async {
    final url = widget.imageUrl.trim();
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    // 1. Check in-memory bytes cache first (0ms instant render)
    if (_bytesCache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _imageBytes = _bytesCache[url];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    // 2. Support base64 data URI directly
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma != -1) {
        try {
          final bytes = base64Decode(url.substring(comma + 1));
          _bytesCache[url] = bytes;
          if (mounted) {
            setState(() {
              _imageBytes = bytes;
              _isLoading = false;
              _hasError = false;
            });
          }
          return;
        } catch (_) {}
      }
    }

    // 3. Check if local file path on device
    if (url.startsWith('/') ||
        url.startsWith('file://') ||
        url.contains(':\\')) {
      final cleanPath = url.replaceAll('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        try {
          final bytes = await file.readAsBytes();
          _bytesCache[url] = bytes;
          if (mounted) {
            setState(() {
              _imageBytes = bytes;
              _isLoading = false;
              _hasError = false;
            });
          }
          return;
        } catch (_) {}
      }
    }

    // 4. Check URL cache
    if (_urlCache.containsKey(url)) {
      _resolvedUrl = _urlCache[url];
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      }
      _tryDownloadBytesPreemptively(url, _resolvedUrl!);
      return;
    }

    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      final isRawCloudStorage =
          (host.contains('cloudflarestorage.com') ||
              host.contains('r2') ||
              host.contains('amazonaws.com') ||
              host.contains('s3')) &&
          !url.contains('X-Amz-Signature') &&
          !url.contains('X-Amz-Algorithm');

      String resolvedUrl;

      if (!uri.hasScheme &&
          (url.startsWith('/api/') || url.startsWith('/storage/'))) {
        final cleanPath = url.startsWith('/api/v1')
            ? url.replaceFirst('/api/v1', '')
            : url;
        resolvedUrl = '${ApiEndpoints.baseUrl}$cleanPath';
      } else if (isRawCloudStorage || !uri.hasScheme) {
        // Extract key from R2 / S3 path
        String targetKey;
        final segments = uri.pathSegments;
        if (segments.length > 1 &&
            (segments.first.toLowerCase() == 'karatflow' ||
                segments.first.toLowerCase() == 'karratflow')) {
          targetKey = segments.skip(1).join('/');
        } else if (segments.isNotEmpty) {
          targetKey = segments.join('/');
        } else {
          targetKey = url.replaceFirst(RegExp(r'^/+'), '');
        }

        // Direct 100% reliable server view proxy endpoint (used by Admin Panel)
        resolvedUrl =
            '${ApiEndpoints.baseUrl}/storage/view?key=${Uri.encodeQueryComponent(targetKey)}';
      } else if (url.contains('X-Amz-Algorithm') ||
          url.contains('X-Amz-Signature')) {
        resolvedUrl = url;
      } else {
        resolvedUrl = url;
      }

      _urlCache[url] = resolvedUrl;

      if (mounted) {
        setState(() {
          _resolvedUrl = resolvedUrl;
          _isLoading = false;
          _hasError = false;
        });
      }

      _tryDownloadBytesPreemptively(url, resolvedUrl);
    } catch (e) {
      _tryDownloadBytesFallback(url);
    }
  }

  Future<void> _tryDownloadBytesPreemptively(
    String originalUrl,
    String targetUrl,
  ) async {
    try {
      final api = KaratFlowApiRepository();
      final bytes = await api.downloadStoredFile(targetUrl);
      if (bytes.isNotEmpty && mounted) {
        _bytesCache[originalUrl] = bytes;
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (_) {}
  }

  Future<void> _tryDownloadBytesFallback(String originalUrl) async {
    try {
      final api = KaratFlowApiRepository();
      final bytes = await api.downloadStoredFile(originalUrl);
      if (bytes.isNotEmpty && mounted) {
        _bytesCache[originalUrl] = bytes;
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CommonProgressIndicator(
            size: 24,
            label: widget.loadingLabel ?? 'Loading image...',
          ),
        ),
      );
    }

    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      return Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildNetworkOrError(),
      );
    }

    return _buildNetworkOrError();
  }

  Widget _buildNetworkOrError() {
    if (_hasError || _resolvedUrl == null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!();
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.broken_image_outlined, color: AppColors.muted, size: 32),
            SizedBox(height: 4),
            Text(
              'Image Preview Unavailable',
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    return Image.network(
      _resolvedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
            color: AppColors.emerald,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        _tryDownloadBytesFallback(widget.imageUrl);
        if (widget.errorBuilder != null) {
          return widget.errorBuilder!();
        }
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.danger,
            size: 32,
          ),
        );
      },
    );
  }
}
