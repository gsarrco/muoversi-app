import 'package:muoversi/src/models/station.dart';

class StationDetailsArguments {
  final Station depStation;
  final Station? arrStation;

  const StationDetailsArguments({
    required this.depStation,
    this.arrStation,
  });

  factory StationDetailsArguments.fromJson(Map<String, dynamic> json) {
    return StationDetailsArguments(
      depStation: Station.fromJson(json['depStation']),
      arrStation: json['arrStation'] != null
          ? Station.fromJson(json['arrStation'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'depStation': depStation.toJson(),
      'arrStation': arrStation?.toJson(),
    };
  }
}
