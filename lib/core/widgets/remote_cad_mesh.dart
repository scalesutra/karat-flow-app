import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Downloads and renders an uploaded binary/ASCII STL or OBJ mesh.
class RemoteCadMesh extends StatefulWidget {
  const RemoteCadMesh({
    super.key,
    required this.modelUrl,
    required this.rotationX,
    required this.rotationY,
    required this.metalColor,
    required this.isWireframe,
  });

  final String modelUrl;
  final double rotationX;
  final double rotationY;
  final Color metalColor;
  final bool isWireframe;

  @override
  State<RemoteCadMesh> createState() => _RemoteCadMeshState();
}

class _RemoteCadMeshState extends State<RemoteCadMesh> {
  List<_MeshTriangle>? _triangles;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RemoteCadMesh oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modelUrl != widget.modelUrl) _load();
  }

  Future<void> _load() async {
    setState(() {
      _triangles = null;
      _error = null;
    });
    try {
      final uri = Uri.tryParse(widget.modelUrl);
      if (uri == null || !uri.hasScheme) {
        throw const FormatException('The CAD model URL is invalid.');
      }
      final response = await Dio().get<List<int>>(
        widget.modelUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const FormatException('The uploaded CAD file is empty.');
      }
      final parsed = _CadMeshParser.parse(Uint8List.fromList(data));
      if (!mounted) return;
      setState(() => _triangles = parsed);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_outlined,
                color: AppColors.danger,
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'Could not load the uploaded CAD model.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final triangles = _triangles;
    if (triangles == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.emerald),
      );
    }

    return CustomPaint(
      painter: _CadMeshPainter(
        triangles: triangles,
        rotationX: widget.rotationX,
        rotationY: widget.rotationY,
        metalColor: widget.metalColor,
        isWireframe: widget.isWireframe,
      ),
      size: Size.infinite,
    );
  }
}

abstract final class _CadMeshParser {
  static const int _maxRenderedTriangles = 4000;

  static List<_MeshTriangle> parse(Uint8List bytes) {
    final triangles = _looksLikeBinaryStl(bytes)
        ? _parseBinaryStl(bytes)
        : _parseTextMesh(bytes);
    if (triangles.isEmpty) {
      throw const FormatException('No triangles were found in the CAD file.');
    }
    return _normalizeAndLimit(triangles);
  }

  static bool _looksLikeBinaryStl(Uint8List bytes) {
    if (bytes.length < 84) return false;
    final count = ByteData.sublistView(bytes).getUint32(80, Endian.little);
    return count > 0 && 84 + (count * 50) <= bytes.length;
  }

  static List<_MeshTriangle> _parseBinaryStl(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final count = data.getUint32(80, Endian.little);
    final triangles = <_MeshTriangle>[];
    for (var index = 0; index < count; index++) {
      final offset = 84 + (index * 50) + 12;
      if (offset + 36 > bytes.length) break;
      triangles.add(
        _MeshTriangle(
          _readVector(data, offset),
          _readVector(data, offset + 12),
          _readVector(data, offset + 24),
        ),
      );
    }
    return triangles;
  }

  static _Vector3 _readVector(ByteData data, int offset) => _Vector3(
    data.getFloat32(offset, Endian.little),
    data.getFloat32(offset + 4, Endian.little),
    data.getFloat32(offset + 8, Endian.little),
  );

  static List<_MeshTriangle> _parseTextMesh(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final obj = _parseObj(text);
    if (obj.isNotEmpty) return obj;

    final number = r'[-+]?(?:\d*\.?\d+)(?:[eE][-+]?\d+)?';
    final vertexPattern = RegExp(
      'vertex\\s+($number)\\s+($number)\\s+($number)',
      caseSensitive: false,
    );
    final vertices = vertexPattern
        .allMatches(text)
        .map(
          (match) => _Vector3(
            double.parse(match.group(1)!),
            double.parse(match.group(2)!),
            double.parse(match.group(3)!),
          ),
        )
        .toList();
    final triangles = <_MeshTriangle>[];
    for (var index = 0; index + 2 < vertices.length; index += 3) {
      triangles.add(
        _MeshTriangle(
          vertices[index],
          vertices[index + 1],
          vertices[index + 2],
        ),
      );
    }
    return triangles;
  }

  static List<_MeshTriangle> _parseObj(String text) {
    final vertices = <_Vector3>[];
    final triangles = <_MeshTriangle>[];
    for (final rawLine in const LineSplitter().convert(text)) {
      final line = rawLine.trim();
      if (line.startsWith('v ')) {
        final values = line.split(RegExp(r'\s+'));
        if (values.length >= 4) {
          vertices.add(
            _Vector3(
              double.parse(values[1]),
              double.parse(values[2]),
              double.parse(values[3]),
            ),
          );
        }
      } else if (line.startsWith('f ')) {
        final values = line.split(RegExp(r'\s+')).skip(1);
        final indices = <int>[];
        for (final value in values) {
          final parsed = int.tryParse(value.split('/').first);
          if (parsed == null) continue;
          final resolved = parsed > 0 ? parsed - 1 : vertices.length + parsed;
          if (resolved >= 0 && resolved < vertices.length) {
            indices.add(resolved);
          }
        }
        for (var index = 1; index + 1 < indices.length; index++) {
          triangles.add(
            _MeshTriangle(
              vertices[indices[0]],
              vertices[indices[index]],
              vertices[indices[index + 1]],
            ),
          );
        }
      }
    }
    return triangles;
  }

  static List<_MeshTriangle> _normalizeAndLimit(List<_MeshTriangle> triangles) {
    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    var maxZ = double.negativeInfinity;
    for (final triangle in triangles) {
      for (final point in triangle.points) {
        minX = math.min(minX, point.x);
        minY = math.min(minY, point.y);
        minZ = math.min(minZ, point.z);
        maxX = math.max(maxX, point.x);
        maxY = math.max(maxY, point.y);
        maxZ = math.max(maxZ, point.z);
      }
    }
    final center = _Vector3(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
      (minZ + maxZ) / 2,
    );
    final span = math.max(maxX - minX, math.max(maxY - minY, maxZ - minZ));
    if (!span.isFinite || span <= 0) {
      throw const FormatException('The CAD mesh has invalid dimensions.');
    }
    final step = math.max(1, (triangles.length / _maxRenderedTriangles).ceil());
    final normalized = <_MeshTriangle>[];
    for (var index = 0; index < triangles.length; index += step) {
      final triangle = triangles[index];
      _Vector3 normalize(_Vector3 point) => _Vector3(
        (point.x - center.x) / span,
        (point.y - center.y) / span,
        (point.z - center.z) / span,
      );
      normalized.add(
        _MeshTriangle(
          normalize(triangle.a),
          normalize(triangle.b),
          normalize(triangle.c),
        ),
      );
    }
    return normalized;
  }
}

class _CadMeshPainter extends CustomPainter {
  _CadMeshPainter({
    required this.triangles,
    required this.rotationX,
    required this.rotationY,
    required this.metalColor,
    required this.isWireframe,
  });

  final List<_MeshTriangle> triangles;
  final double rotationX;
  final double rotationY;
  final Color metalColor;
  final bool isWireframe;

  _Vector3 _rotate(_Vector3 point) {
    final x1 = point.x * math.cos(rotationY) - point.z * math.sin(rotationY);
    final z1 = point.x * math.sin(rotationY) + point.z * math.cos(rotationY);
    final y2 = point.y * math.cos(rotationX) - z1 * math.sin(rotationX);
    final z2 = point.y * math.sin(rotationX) + z1 * math.cos(rotationX);
    return _Vector3(x1, y2, z2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = math.min(size.width, size.height) * 0.86;
    final rendered = triangles.map((triangle) {
      final a = _rotate(triangle.a);
      final b = _rotate(triangle.b);
      final c = _rotate(triangle.c);
      return _RenderedTriangle(a, b, c, (a.z + b.z + c.z) / 3);
    }).toList()..sort((left, right) => left.depth.compareTo(right.depth));

    Offset project(_Vector3 point) =>
        Offset(center.dx + point.x * scale, center.dy - point.y * scale);

    for (final triangle in rendered) {
      final a = project(triangle.a);
      final b = project(triangle.b);
      final c = project(triangle.c);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..close();
      final area =
          (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
      final brightness = (0.28 + area.abs() / 9000)
          .clamp(0.28, 0.78)
          .toDouble();
      if (!isWireframe) {
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = Color.lerp(Colors.black, metalColor, brightness)!,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isWireframe ? 0.8 : 0.25
          ..color = isWireframe
              ? metalColor.withValues(alpha: 0.72)
              : Colors.black.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CadMeshPainter oldDelegate) =>
      oldDelegate.triangles != triangles ||
      oldDelegate.rotationX != rotationX ||
      oldDelegate.rotationY != rotationY ||
      oldDelegate.metalColor != metalColor ||
      oldDelegate.isWireframe != isWireframe;
}

class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _MeshTriangle {
  const _MeshTriangle(this.a, this.b, this.c);

  final _Vector3 a;
  final _Vector3 b;
  final _Vector3 c;

  List<_Vector3> get points => [a, b, c];
}

class _RenderedTriangle {
  const _RenderedTriangle(this.a, this.b, this.c, this.depth);

  final _Vector3 a;
  final _Vector3 b;
  final _Vector3 c;
  final double depth;
}
