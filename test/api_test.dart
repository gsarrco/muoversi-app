import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/models/offset.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:muoversi/src/models/stop_time.dart';

import 'api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() async {
  await dotenv.load();
  final client = MockClient();
  group('searchStations', () {
    test('returns a List of Station if the http call completes successfully',
        () async {
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
          "source": "treni",
          "ids": "S02593"
        }
      ];

      when(client.get(Uri.parse(url)))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(await searchStations(client, query, limit), isA<List<Station>>());
    });
  });

  group('getStopTimes', () {
    test('returns a List of StopTime if the http call completes successfully',
        () async {
      const depStopsIds = 'aut_6021,aut_6022';
      const source = 'aut';
      const day = '2023-11-25';
      const offsetByStopsIds = '';
      const limit = 1;
      const startTime = '12:30';
      const arrStopsIds = null;
      const direction = 1;

      const Offset? offset = null;

      final baseApiUrl = dotenv.env['BASE_API_URL'];
      final uri = Uri.parse("$baseApiUrl/stop_times").replace(queryParameters: {
        'dep_stops_ids': depStopsIds,
        'source': source,
        'day': day,
        'offset_by_ids': offsetByStopsIds,
        'limit': limit.toString(),
        'start_time': startTime,
        'arr_stops_ids': arrStopsIds,
        'direction': direction.toString(),
      });
      const result = [
        [
          {
            "id": 15107356,
            "sched_arr_dt": "2023-11-25T12:30:00",
            "sched_dep_dt": "2023-11-25T12:30:00",
            "orig_dep_date": "2023-11-25",
            "platform": "",
            "orig_id": "6084",
            "dest_text": "FAVARO",
            "number": 39721,
            "route_name": "T1",
            "source": "aut",
            "stop_id": "aut_6022"
          }
        ]
      ];

      when(client.get(uri))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(
          await getStopTimes(client, depStopsIds, source, day, startTime,
              offset, limit, arrStopsIds),
          isA<List<List<StopTime>>>());
    });
  });
}
