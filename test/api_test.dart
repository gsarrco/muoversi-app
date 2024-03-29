import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/helpers/search-stations.dart';
import 'package:muoversi/src/models/offset.dart';
import 'package:muoversi/src/models/source.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:muoversi/src/models/stop_time.dart';

import 'api_test.mocks.dart';

@GenerateMocks([http.Client])
void main() async {
  final client = MockClient();
  group('api', () {
    test('returns a List of Station if the http call completes successfully',
        () async {
      const query = 'test';
      const limit = 1;
      const List<String> sources = [
        'venezia-aut',
        'venezia-nav',
        'venezia-treni'
      ];
      final uri =
          Uri.parse("$baseApiUrl/search/stations").replace(queryParameters: {
        'q': query,
        'limit': limit.toString(),
        'sources': sources.join(','),
      });

      const result = [
        {
          "id": "S02593",
          "name": "Venezia Santa Lucia",
          "lat": 45.441397,
          "lon": 12.320462,
          "source": "venezia-treni",
          "ids": "S02593"
        }
      ];

      when(client.get(uri))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(await searchStations(client, query, limit, sources),
          isA<List<Station>>());
    });
    test('returns only treni stations', () async {
      const query = 'Venezia';
      const limit = 1;
      const List<String> sources = ['venezia-treni'];
      final uri =
          Uri.parse("$baseApiUrl/search/stations").replace(queryParameters: {
        'q': query,
        'limit': limit.toString(),
        'sources': sources.join(','),
      });

      const result = [
        {
          "id": "S02593",
          "name": "Venezia Santa Lucia",
          "lat": 45.441397,
          "lon": 12.320462,
          "source": "venezia-treni",
          "ids": "S02593"
        }
      ];

      when(client.get(uri))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(await searchStations(client, query, limit, sources),
          isA<List<Station>>());
    });
  });

  group('getStopTimes', () {
    test('iso8601 datetimes should be formatted correctly', () {
      final dt = DateTime.parse('2023-11-25T12:30:00');
      expect(dt.toIso8601String(), '2023-11-25T12:30:00.000');
    });

    test('returns a List of StopTime if the http call completes successfully',
        () async {
      const depStopsIds = 'aut_6021,aut_6022';
      const source = 'venezia-aut';
      final startDt = DateTime.parse('2023-11-25T12:30:00');
      const offsetByStopsIds = '';
      const limit = 1;
      const arrStopsIds = null;
      const direction = 1;

      const Offset? offset = null;

      final uri = Uri.parse("$baseApiUrl/stop_times").replace(queryParameters: {
        'dep_stops_ids': depStopsIds,
        'source': source,
        'offset_by_ids': offsetByStopsIds,
        'limit': limit.toString(),
        'start_dt': startDt.toIso8601String(),
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
            "source": "venezia-aut",
            "stop_id": "aut_6022"
          }
        ]
      ];

      when(client.get(uri))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(
          await getStopTimes(
              client, depStopsIds, source, startDt, offset, limit, arrStopsIds),
          isA<List<List<StopTime>>>());
    });
  });
  group('searchStations', () {
    test(
        'returns only treni stations and exclude Venezia Santa Lucia after the api',
        () async {
      const query = 'Venezia';
      const maxLimit = 3;
      const slice = 2;
      const List<String> sources = ['venezia-treni'];
      // hide Venezia Santa Lucia
      const List<String> hideIds = ['S02593'];

      final uri =
          Uri.parse("$baseApiUrl/search/stations").replace(queryParameters: {
        'q': query,
        'limit': maxLimit.toString(),
        'sources': sources.join(','),
      });

      const httpResult = [
        {
          "id": "S02593",
          "name": "Venezia Santa Lucia",
          "lat": 45.441397,
          "lon": 12.320462,
          "source": "venezia-treni",
          "ids": "S02593"
        },
        {
          "id": "S02592",
          "name": "Venezia Mestre",
          "lat": 45.441396,
          "lon": 12.320461,
          "source": "venezia-treni",
          "ids": "S02590"
        },
        {
          "id": "S02591",
          "name": "Venezia Porto Marghera",
          "lat": 45.441395,
          "lon": 12.320460,
          "source": "venezia-treni",
          "ids": "S02591"
        }
      ];

      when(client.get(uri))
          .thenAnswer((_) async => http.Response(jsonEncode(httpResult), 200));

      List<Station> result = await searchStationsAndHide(
          client, query, maxLimit, slice, sources, hideIds);

      expect(result.length, 2);
      expect(result[0].toJson(), httpResult[1]);
    });
  });
  group('getSourcesFromCity', () {
    test('returns a List of Source if the http call completes successfully',
        () async {
      const city = 'venezia';
      const url = '$baseApiUrl/cities/$city';
      const result = [
        {"name": "venezia-aut", "color": "#FF9800", "icon_code": 57813}
      ];

      when(client.get(Uri.parse(url)))
          .thenAnswer((_) async => http.Response(jsonEncode(result), 200));

      expect(await getSourcesFromCity(client, city), isA<List<Source>>());
    });
  });
}
