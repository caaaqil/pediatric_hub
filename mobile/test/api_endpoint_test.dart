// The address box accepts whatever a person naturally types.

import 'package:flutter_test/flutter_test.dart';
import 'package:pediatric_health_hub_mobile/core/storage/api_endpoint.dart';

void main() {
  test('normalise accepts the forms a user would type', () {
    const String want = 'http://10.59.13.45:3000/api/v1';

    expect(ApiEndpoint.normalise('10.59.13.45'), want);
    expect(ApiEndpoint.normalise('10.59.13.45:3000'), want);
    expect(ApiEndpoint.normalise('http://10.59.13.45:3000'), want);
    expect(ApiEndpoint.normalise('http://10.59.13.45:3000/'), want);
    expect(ApiEndpoint.normalise('  10.59.13.45  '), want);
    expect(ApiEndpoint.normalise('http://10.59.13.45:3000/api/v1'), want);
  });

  test('non-default port is preserved', () {
    expect(
      ApiEndpoint.normalise('192.168.1.5:8080'),
      'http://192.168.1.5:8080/api/v1',
    );
  });

  test('empty input clears the override', () {
    expect(ApiEndpoint.normalise(''), '');
    expect(ApiEndpoint.normalise('   '), '');
  });
}
