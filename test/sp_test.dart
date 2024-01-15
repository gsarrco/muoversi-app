import 'package:flutter_test/flutter_test.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:muoversi/src/models/station_details_arguments.dart';

void main() {
  group('shared-preferences', () {
    const limit = 3;
    const Station s1 = Station(
      id: 'id1',
      name: 'name1',
      source: 'source1',
      ids: 'id1',
      lat: 1.0,
      lon: 1.0,
    );
    const Station s2 = Station(
      id: 'id2',
      name: 'name2',
      source: 'source1',
      ids: 'id2',
      lat: 2.0,
      lon: 2.0,
    );
    const Station s3 = Station(
      id: 'id3',
      name: 'name3',
      source: 'source2',
      ids: 'id3',
      lat: 3.0,
      lon: 3.0,
    );
    const Station s4 = Station(
      id: 'id4',
      name: 'name4',
      source: 'source2',
      ids: 'id4',
      lat: 4.0,
      lon: 4.0,
    );
    test('empty', () {
      // empty existing items
      const List<String> pList = [];
      // new item
      const StationDetailsArguments arg1 = StationDetailsArguments(
        depStation: s1,
      );
      expect(arg1.getNewPrefList(pList, limit), [arg1.toJsonString()]);
    });
    test('append arrStation and move up', () {
      // existing items
      final List<String> pList = [
        const StationDetailsArguments(depStation: s1).toJsonString(),
        const StationDetailsArguments(depStation: s2).toJsonString(),
        const StationDetailsArguments(depStation: s3).toJsonString(),
      ];
      // new item
      const StationDetailsArguments arg1 = StationDetailsArguments(
        depStation: s2,
        arrStation: s3,
      );

      expect(arg1.getNewPrefList(pList, limit), [
        arg1.toJsonString(),
        pList[0],
        pList[2],
      ]);
    });
    test('new item', () {
      // existing items
      final List<String> pList = [
        const StationDetailsArguments(depStation: s1).toJsonString(),
        const StationDetailsArguments(depStation: s2).toJsonString(),
        const StationDetailsArguments(depStation: s3).toJsonString(),
      ];
      // new item
      const StationDetailsArguments arg1 = StationDetailsArguments(
        depStation: s4,
      );

      expect(arg1.getNewPrefList(pList, limit), [
        arg1.toJsonString(),
        pList[0],
        pList[1],
      ]);
    });
    test('move up item', () {
      // existing items
      final List<String> pList = [
        const StationDetailsArguments(depStation: s1).toJsonString(),
        const StationDetailsArguments(depStation: s3, arrStation: s4)
            .toJsonString(),
        const StationDetailsArguments(depStation: s2).toJsonString(),
      ];
      // new item
      const StationDetailsArguments arg1 = StationDetailsArguments(
        depStation: s3,
        arrStation: s4,
      );

      expect(arg1.getNewPrefList(pList, limit), [
        arg1.toJsonString(),
        pList[0],
        pList[2],
      ]);
    });
  });
}
