import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/station.dart';
import 'package:http/http.dart' as http;

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
