class StopTime {
  final int id;
  final DateTime? schedArrDt;
  final DateTime? schedDepDt;
  final String origDepDate;
  final String? platform;
  final String origId;
  final String destText;
  final int number;
  final String routeName;
  final String source;
  final String stopId;

  StopTime({
    required this.id,
    this.schedArrDt,
    this.schedDepDt,
    required this.origDepDate,
    this.platform,
    required this.origId,
    required this.destText,
    required this.number,
    required this.routeName,
    required this.source,
    required this.stopId,
  });

  factory StopTime.fromJson(Map<String, dynamic> json) {
    return StopTime(
      id: json['id'],
      schedArrDt: json['sched_arr_dt'] != null
          ? DateTime.parse(json['sched_arr_dt'])
          : null,
      schedDepDt: json['sched_dep_dt'] != null
          ? DateTime.parse(json['sched_dep_dt'])
          : null,
      origDepDate: json['orig_dep_date'],
      platform: json['platform'],
      origId: json['orig_id'],
      destText: json['dest_text'],
      number: json['number'],
      routeName: json['route_name'],
      source: json['source'],
      stopId: json['stop_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sched_arr_dt': schedArrDt,
      'sched_dep_dt': schedDepDt,
      'orig_dep_date': origDepDate,
      'platform': platform,
      'orig_id': origId,
      'dest_text': destText,
      'number': number,
      'route_name': routeName,
      'source': source,
      'stop_id': stopId,
    };
  }
}
