import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_ops_mobile/data/models/api_models.dart';

void main() {
  test('presigned upload response accepts documented viewUrl field', () {
    final upload = ApiPresignedUrl.fromJson({
      'uploadUrl': 'https://s3.example.com/upload?signature=test',
      'fileKey': 'sketches/user-123/concept.png',
      'viewUrl': '/api/v1/storage/view?key=sketches%2Fuser-123%2Fconcept.png',
    });

    expect(upload.fileKey, 'sketches/user-123/concept.png');
    expect(
      upload.fileUrl,
      '/api/v1/storage/view?key=sketches%2Fuser-123%2Fconcept.png',
    );
  });

  test('sketch response retains documented ownership and timestamps', () {
    final sketch = ApiSketch.fromJson({
      'id': 'sketch-uuid',
      'designNumber': 'SKT-2026-0042',
      'title': 'Royal Peacock Antique Bridal Choker',
      'sketchUrl': 'sketches/user-123/concept.png',
      'status': 'CHANGES_REQUESTED',
      'version': 2,
      'designerId': 'usr-sketcher-01',
      'createdAt': '2026-08-29T07:15:00.000Z',
      'updatedAt': '2026-08-29T07:25:00.000Z',
    });

    expect(sketch.status, 'CHANGES_REQUESTED');
    expect(sketch.designerId, 'usr-sketcher-01');
    expect(sketch.updatedAt, '2026-08-29T07:25:00.000Z');
  });
}
