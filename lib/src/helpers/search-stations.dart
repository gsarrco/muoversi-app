import 'package:http/http.dart' as http;

import '../models/station.dart';
import 'api.dart';

Future<List<Station>> searchStationsAndHide(http.Client client, String query,
    int maxLimit, int slice, List<String> sources,
    [List<String>? hideIds]) async {
  List<Station> stations =
      await searchStations(client, query, maxLimit, sources);
  if (hideIds != null && hideIds.isNotEmpty) {
    stations.removeWhere((station) => hideIds.contains(station.id));
  }
  return stations.take(slice).toList();
}
