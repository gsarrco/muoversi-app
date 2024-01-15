import 'dart:convert';

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

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory StationDetailsArguments.fromJsonString(String jsonString) {
    return StationDetailsArguments.fromJson(jsonDecode(jsonString));
  }

  List<String> getNewPrefList(List<String> pList, int limit) {
    final List<StationDetailsArguments> argList =
        pList.map((e) => StationDetailsArguments.fromJsonString(e)).toList();

    argList.removeWhere((e) =>
        e.depStation.id == depStation.id &&
            e.depStation.source == depStation.source &&
            (e.arrStation == null) ||
        (e.arrStation != null &&
            e.arrStation?.id == arrStation?.id &&
            e.arrStation?.source == arrStation?.source));

    argList.insert(0, this);

    return argList.map((e) => e.toJsonString()).take(limit).toList();
  }
}
