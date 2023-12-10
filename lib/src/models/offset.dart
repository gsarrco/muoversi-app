class Offset {
  final int direction;
  final List<int>? stopTimesIds;
  final DateTime? time;

  Offset({
    required this.direction,
    this.stopTimesIds,
    this.time,
  });
}
