import 'package:http/http.dart' as http;

import '../models/station.dart';
import 'api.dart';

Future<List<Station>> searchStationsAndHide(
    http.Client client, String query, int maxLimit, int slice,
    [String? onlySource, List<String>? hideIds]) async {
  List<Station> stations =
      await searchStations(client, query, maxLimit, onlySource);
  if (hideIds != null && hideIds.isNotEmpty) {
    stations.removeWhere((station) => hideIds.contains(station.id));
  }
  return stations.take(slice).toList();
}
