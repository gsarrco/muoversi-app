import "package:muoversi/src/models/offset.dart";
import "package:muoversi/src/models/stop_time.dart";

Offset createOffset(List<StopTime> stopTimes, int direction) {
  if (direction != 1 && direction != -1) {
    throw Exception("Direction in createOffset can only be 1 or -1");
  }

  final int loopStart = direction == 1 ? stopTimes.length - 1 : 0;
  final int loopEnd = direction == 1 ? 0 : stopTimes.length - 1;

  DateTime? time;
  List<int> stopTimesIds = [];
  for (int i = loopStart; i != loopEnd; i -= direction) {
    final stopTime = stopTimes[i];
    if (stopTime.schedDepDt != null) {
      time ??= stopTime.schedDepDt; // if first iteration, set time

      if (stopTime.schedDepDt!.isAtSameMomentAs(time!)) {
        stopTimesIds.add(stopTime.id);
      } else {
        break; // if we have overpassed the time, exit the loop
      }
    }
  }

  return Offset(
    direction: direction,
    stopTimesIds: stopTimesIds,
    time: time,
  );
}
