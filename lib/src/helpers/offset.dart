import "package:intl/intl.dart";
import "package:muoversi/src/models/offset.dart";
import "package:muoversi/src/models/stop_time.dart";

Offset createOffset(List<StopTime> stopTimes, int direction) {
  if (direction != 1 && direction != -1) {
    throw Exception("Direction in createOffset can only be 1 or -1");
  }

  final int loopStart = direction == 1 ? stopTimes.length - 1 : 0;
  final int loopEnd = direction == 1 ? 0 : stopTimes.length - 1;

  String? time;
  List<int> stopTimesIds = [];
  for (int i = loopStart; i != loopEnd; i -= direction) {
    final stopTime = stopTimes[i];
    if (stopTime.schedDepDt != null) {
      final sTTime = DateFormat("HH:mm").format(stopTime.schedDepDt!);
      time ??= sTTime; // if first iteration, set time

      if (sTTime == time) {
        stopTimesIds.add(stopTime.id);
      } else {
        break; // if we have overpassed the time, exit the loop
      }
    }
  }

  return Offset(
    direction: direction,
    stopTimesIds: stopTimesIds,
    time: time!,
  );
}
