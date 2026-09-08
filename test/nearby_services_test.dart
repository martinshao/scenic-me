import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scenic_me/features/create/data/nearby_services.dart';

void main() {
  test('地点搜索携带应用标识、城市范围并缓存重复查询', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount += 1;
      expect(request.headers['user-agent'], 'ScenicMe/Test');
      expect(request.url.queryParameters['q'], '灵隐寺, 杭州');
      expect(request.url.queryParameters['limit'], '5');
      return http.Response(
        '[{"name":"灵隐寺","display_name":"浙江省杭州市西湖区灵隐寺",'
        '"lat":"30.2409","lon":"120.1016"}]',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = NominatimPlaceSearchService(
      client: client,
      endpoint: Uri.parse('https://example.test/search'),
      userAgent: 'ScenicMe/Test',
    );

    final first = await service.search(query: '灵隐寺', city: '杭州');
    final second = await service.search(query: '灵隐寺', city: '杭州');

    expect(first.single.name, '灵隐寺');
    expect(first.single.point.latitude, 30.2409);
    expect(second.single.displayName, contains('杭州市'));
    expect(requestCount, 1);
  });
}
