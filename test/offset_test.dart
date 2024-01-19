import 'package:flutter_test/flutter_test.dart';
import 'package:muoversi/src/helpers/offset.dart';
import 'package:muoversi/src/models/offset.dart';
import 'package:muoversi/src/models/stop_time.dart';

void main() {
  group('offset', () {
    final List<StopTime> stopTimes = [
      [
        {
          "id": 15124762,
          "sched_arr_dt": "2023-11-25T12:30:00",
          "sched_dep_dt": "2023-11-25T12:30:00",
          "orig_dep_date": "2023-11-25",
          "platform": "",
          "orig_id": "507",
          "dest_text": "MIRANO",
          "number": 41728,
          "route_name": "7E",
          "source": "venezia-aut",
          "stop_id": "aut_507"
        }
      ],
      [
        {
          "id": 15090868,
          "sched_arr_dt": "2023-11-25T12:32:00",
          "sched_dep_dt": "2023-11-25T12:32:00",
          "orig_dep_date": "2023-11-25",
          "platform": "",
          "orig_id": "505",
          "dest_text": "FAVARO ALTINIA",
          "number": 37325,
          "route_name": "19",
          "source": "venezia-aut",
          "stop_id": "aut_505"
        }
      ],
      [
        {
          "id": 15106272,
          "sched_arr_dt": "2023-11-25T12:34:00",
          "sched_dep_dt": "2023-11-25T12:34:00",
          "orig_dep_date": "2023-11-25",
          "platform": "",
          "orig_id": "509",
          "dest_text": "MESTRE CENTRO",
          "number": 39136,
          "route_name": "4L",
          "source": "venezia-aut",
          "stop_id": "aut_509"
        }
      ],
      [
        {
          "id": 15099717,
          "sched_arr_dt": "2023-11-25T12:34:00",
          "sched_dep_dt": "2023-11-25T12:34:00",
          "orig_dep_date": "2023-11-25",
          "platform": "",
          "orig_id": "510",
          "dest_text": "V.LE D.STURZO",
          "number": 38269,
          "route_name": "2",
          "source": "venezia-aut",
          "stop_id": "aut_510"
        }
      ]
    ].map((e) => StopTime.fromJson(e[0])).toList();
    test('createOffset for direction 1', () {
      final Offset offset = createOffset(stopTimes, 1);
      expect(offset.direction, 1);
      expect(offset.stopTimesIds, [15099717, 15106272]);
      expect(offset.time, DateTime.parse('2023-11-25T12:34:00'));
    });
    test('createOffset for direction -1', () {
      final Offset offset = createOffset(stopTimes, -1);
      expect(offset.direction, -1);
      expect(offset.stopTimesIds, [15124762]);
      expect(offset.time, DateTime.parse('2023-11-25T12:30:00'));
    });
    test('createOffset for direction 0 throws exception', () {
      expect(() => createOffset(stopTimes, 0), throwsException);
    });
  });
}
