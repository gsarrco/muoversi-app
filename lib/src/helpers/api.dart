import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:muoversi/src/models/stop_time.dart';

import '../models/offset.dart';
import '../models/source.dart';
import '../models/station.dart';

const String baseApiUrl = String.fromEnvironment('BASE_API_URL',
    defaultValue: 'https://api.muoversi.app');

Future<List<Station>> searchStations(
    http.Client client, String query, int limit, List<String> sources) async {
  Map<String, String> queryParameters = {
    'q': query,
    'limit': limit.toString(),
    'sources': sources.join(','),
  };

  final uri = Uri.parse("$baseApiUrl/search/stations")
      .replace(queryParameters: queryParameters);

  final response = await client.get(uri);
  if (response.statusCode == 200) {
    Iterable l = json.decode(utf8.decode(response.bodyBytes));
    return List<Station>.from(l.map((model) => Station.fromJson(model)));
  } else {
    throw Exception('Failed to load stations');
  }
}

Future<List<List<StopTime>>> getStopTimes(
    http.Client client,
    String depStopsIds,
    String source,
    DateTime startDt,
    Offset? offset,
    int limit,
    String? arrStopsIds) async {
  String? offsetByStopsIds;
  int direction = 1;
  if (offset != null && offset.direction != 0) {
    offsetByStopsIds = offset.stopTimesIds?.join(',');
    startDt = offset.time!;
    direction = offset.direction;
  }

  final uri = Uri.parse("$baseApiUrl/stop_times").replace(queryParameters: {
    'dep_stops_ids': depStopsIds,
    'source': source,
    'offset_by_ids': offsetByStopsIds,
    'limit': limit.toString(),
    'start_dt': startDt.toIso8601String(),
    'arr_stops_ids': arrStopsIds,
    'direction': direction.toString(),
  });
  final response = await client.get(uri);
  if (response.statusCode == 200) {
    Iterable l = json.decode(utf8.decode(response.bodyBytes));
    return List<List<StopTime>>.from(l.map((model) => List<StopTime>.from(
        model.map((stopTime) => StopTime.fromJson(stopTime)))));
  } else {
    throw Exception('Failed to load stop times');
  }
}

Future<List<Source>> getSourcesFromCity(
    http.Client client, String cityName) async {
  final uri = Uri.parse("$baseApiUrl/cities/$cityName");
  final response = await client.get(uri);
  if (response.statusCode == 200) {
    Iterable l = json.decode(utf8.decode(response.bodyBytes));
    return List<Source>.from(l.map((model) => Source.fromJson(model)));
  } else {
    throw Exception('Failed to load sources from city');
  }
}
