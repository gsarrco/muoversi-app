import 'dart:convert';

import 'package:muoversi/src/models/station.dart';

class StationDetailsArguments {
  final Station depStation;
  final Station? arrStation;
  final bool saved;

  const StationDetailsArguments({
    required this.depStation,
    this.arrStation,
    this.saved = false,
  });

  factory StationDetailsArguments.fromJson(Map<String, dynamic> json,
      [bool saved = false]) {
    return StationDetailsArguments(
      depStation: Station.fromJson(json['depStation']),
      arrStation: json['arrStation'] != null
          ? Station.fromJson(json['arrStation'])
          : null,
      saved: saved,
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

  factory StationDetailsArguments.fromJsonString(String jsonString,
      [bool saved = false]) {
    return StationDetailsArguments.fromJson(jsonDecode(jsonString), saved);
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

  String getTitle(showOnlyArrStation) {
    if (showOnlyArrStation) {
      return arrStation!.name;
    }
    String title = depStation.name;
    if (arrStation != null) {
      title += ' > ${arrStation!.name}';
    }
    return title;
  }

  @override
  bool operator ==(other) =>
      other is StationDetailsArguments &&
      other.depStation.id == depStation.id &&
      other.depStation.source == depStation.source;

  @override
  int get hashCode => depStation.id.hashCode ^ depStation.source.hashCode;
}
