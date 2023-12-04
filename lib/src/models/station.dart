class Station {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String source;
  final String ids;

  const Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.source,
    required this.ids,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      name: json['name'],
      lat: json['lat'],
      lon: json['lon'],
      source: json['source'],
      ids: json['ids'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lon': lon,
      'source': source,
      'ids': ids,
    };
  }
}
