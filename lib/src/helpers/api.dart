import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:muoversi/src/models/stop_time.dart';

import '../models/offset.dart';
import '../models/station.dart';

Future<List<Station>> searchStations(
    http.Client client, String query, int limit) async {
  final baseApiUrl = dotenv.env['BASE_API_URL'];
  query = Uri.encodeComponent(query);
  final url = "$baseApiUrl/search/stations?q=$query&limit=$limit";
  print(url);
  final response = await client.get(Uri.parse(url));
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
    String date,
    String startTime,
    Offset? offset,
    int limit,
    String? arrStopsIds) async {
  final baseApiUrl = dotenv.env['BASE_API_URL'];

  String? offsetByStopsIds;
  int direction = 1;
  if (offset != null && offset.direction != 0) {
    offsetByStopsIds = offset.stopTimesIds?.join(',');
    startTime = offset.time!;
    direction = offset.direction;
  }

  final uri = Uri.parse("$baseApiUrl/stop_times").replace(queryParameters: {
    'dep_stops_ids': depStopsIds,
    'source': source,
    'day': date,
    'offset_by_ids': offsetByStopsIds,
    'limit': limit.toString(),
    'start_time': startTime,
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
