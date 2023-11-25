import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:http/http.dart' as http;
import 'api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() async {
  await dotenv.load();
  group('searchStations', () {
    test('returns a List of Station if the http call completes successfully',
        () async {
      final client = MockClient();
      const query = 'test';
      const limit = 1;
      final baseApiUrl = dotenv.env['BASE_API_URL'];
      final url = '$baseApiUrl/search/stations?q=$query&limit=$limit';

      const result = [
        {
          "id": "S02593",
          "name": "Venezia Santa Lucia",
          "lat": 45.441397,
          "lon": 12.320462,
          "source": "treni"
        }
      ];

      when(client.get(Uri.parse(url)))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(await searchStations(client, query, limit), isA<List<Station>>());
    });
  });
}
