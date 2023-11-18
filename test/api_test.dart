import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:http/http.dart' as http;
import 'package:muoversi/src/models/stop_time.dart';
import 'api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() async {
  await dotenv.load();
  group('searchStations', () {
    test('returns a List of Station if the http call completes successfully',
        () async {
      final client = MockClient();
      const query = 'test';
      final baseApiUrl = dotenv.env['BASE_API_URL'];
      final url = '$baseApiUrl/search/stations?q=$query';

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

      expect(await searchStations(client, query, 4), isA<List<Station>>());
    });
  });

  group('getStopTimes', () {
    test('returns a List of StopTime if the http call completes successfully',
        () async {
      final client = MockClient();
      const depStopsIds = 'aut_6021,aut_6022';
      const source = 'aut';
      const date = '2023-11-18';
      const offset = 0;
      const limit = 1;
      final baseApiUrl = dotenv.env['BASE_API_URL'];
      final uri = Uri.parse("$baseApiUrl/stop_times").replace(queryParameters: {
        'dep_stops_ids': depStopsIds,
        'source': source,
        'date': date,
        'offset': offset.toString(),
        'limit': limit.toString()
      });
      const result = [
        {
          "id": 1654830,
          "sched_arr_dt": "2023-11-17T00:05:00",
          "sched_dep_dt": "2023-11-17T00:05:00",
          "orig_dep_date": "2023-11-16",
          "platform": "",
          "orig_id": "6084",
          "dest_text": "FAVARO",
          "number": 11295,
          "route_name": "T1",
          "source": "aut",
          "stop_id": "aut_6022"
        }
      ];

      when(client.get(uri))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(
          await getStopTimes(client, depStopsIds, source, date, offset, limit),
          isA<List<StopTime>>());
    });
  });
}
