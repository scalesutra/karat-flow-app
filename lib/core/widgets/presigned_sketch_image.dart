import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/repositories/karatflow_api_repository.dart';
import '../constants/app_colors.dart';
import '../network/api_endpoints.dart';
import 'common_progress_indicator.dart';

/// Ultra-Modern Presigned AWS S3 & Local File Sketch Image Renderer
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
  String? _resolvedUrl;
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

    // Check if local file path on device
    if (url.startsWith('/') ||
        url.startsWith('file://') ||
        url.contains(':\\')) {
      final cleanPath = url.replaceAll('file://', '');
      final file = File(cleanPath);
      if (file.existsSync()) {
        if (mounted) {
          setState(() {
            _resolvedUrl = url;
            _isLoading = false;
            _hasError = false;
          });
        }
        return;
      }
    }

    if (_urlCache.containsKey(url)) {
      if (mounted) {
        setState(() {
          _resolvedUrl = _urlCache[url];
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    try {
      final uri = Uri.parse(url);
      String resolvedUrl;
      if (url.contains('X-Amz-Algorithm')) {
        resolvedUrl = url;
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        resolvedUrl = url;
      } else if (!uri.hasScheme && url.startsWith('/api/')) {
        resolvedUrl = Uri.parse(ApiEndpoints.baseUrl).resolve(url).toString();
      } else if (!uri.hasScheme ||
          url.contains('amazonaws.com') ||
          url.contains('karratflow')) {
        final fileKey = uri.hasScheme
            ? uri.path.replaceFirst(RegExp(r'^/+'), '')
            : url.replaceFirst(RegExp(r'^/+'), '');
        final api = KaratFlowApiRepository();
        final signed = await api.getPresignedDownloadUrl(fileKey);
        if (signed.downloadUrl.isEmpty) {
          throw const FormatException('Storage API returned no download URL.');
        }
        resolvedUrl = signed.downloadUrl;
      } else {
        resolvedUrl =
            '${ApiEndpoints.baseUrl}${url.startsWith('/') ? '' : '/'}$url';
      }

      _urlCache[url] = resolvedUrl;
      if (mounted) {
        setState(() {
          _resolvedUrl = resolvedUrl;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint(
        '⚠️ [PresignedSketchImage] Failed to resolve presigned URL for $url: $e',
      );
      if (mounted) {
        setState(() {
          _resolvedUrl = null;
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

    final targetUrl = _resolvedUrl!;
    if (targetUrl.startsWith('/') ||
        targetUrl.startsWith('file://') ||
        targetUrl.contains(':\\')) {
      final cleanPath = targetUrl.replaceAll('file://', '');
      return Image.file(
        File(cleanPath),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) =>
            widget.errorBuilder?.call() ?? const Icon(Icons.broken_image),
      );
    }

    return Image.network(
      targetUrl,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (_, __, ___) =>
          widget.errorBuilder?.call() ?? const Icon(Icons.broken_image),
    );
  }
}
