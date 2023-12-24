import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/helpers/offset.dart';
import 'package:muoversi/src/models/offset.dart' as stop_time_offset;
import 'package:muoversi/src/models/station.dart';
import 'package:muoversi/src/models/stop_time.dart';
import 'package:muoversi/src/search_stations/station_search_widget.dart';
import 'package:rxdart/rxdart.dart';

class StationDetailsView extends StatefulWidget {
  final Station station;

  StationDetailsView({Key? key, required stationMap})
      : station = Station.fromJson(stationMap),
        super(key: key);

  static const routeName = '/station_details';

  @override
  State<StationDetailsView> createState() => _StationDetailsViewState();
}

class _StationDetailsViewState extends State<StationDetailsView> {
  late BehaviorSubject<List<StopTime>> _stopTimesController;
  late ScrollController _scrollController;
  final int limit = 12;
  stop_time_offset.Offset? minusOffset = stop_time_offset.Offset(direction: 0);
  stop_time_offset.Offset? plusOffset = stop_time_offset.Offset(direction: 0);
  Station? arrivalStation;

  @override
  void initState() {
    super.initState();
    _stopTimesController = BehaviorSubject<List<StopTime>>.seeded([]);
    _scrollController = ScrollController();

    updateStopTimes(0);

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0 && (plusOffset != null)) {
        updateStopTimes(1);
      }
    }
  }

  void updateStopTimes(int direction) {
    DateTime startDt = DateTime.now();

    stop_time_offset.Offset? offset;
    if (direction == 1) {
      offset = plusOffset;
    }
    if (direction == -1) {
      offset = minusOffset;
    }

    getStopTimes(http.Client(), widget.station.ids, widget.station.source,
            startDt, offset, limit, arrivalStation?.ids)
        .then((newStopTimesList) {
      final newStopTimes = newStopTimesList.map((e) => e[0]).toList();

      switch (direction) {
        case 0:
          if (newStopTimes.isEmpty) {
            minusOffset = null;
          } else {
            minusOffset = createOffset(newStopTimes, -1);
          }

          if (newStopTimes.length < limit) {
            plusOffset = null;
          } else {
            plusOffset = createOffset(newStopTimes, 1);
          }
          break;
        case -1:
          if (newStopTimes.length < limit) {
            minusOffset = null;
          } else {
            minusOffset = createOffset(newStopTimes, -1);
          }
          break;
        case 1:
          if (newStopTimes.length < limit) {
            plusOffset = null;
          } else {
            plusOffset = createOffset(newStopTimes, 1);
          }
          break;
      }

      if (newStopTimes.isEmpty) {
        minusOffset = null;
        plusOffset = null;
      }

      switch (direction) {
        case 0:
          _stopTimesController.value = newStopTimes;
          break;
        case -1:
          _stopTimesController.add(newStopTimes + _stopTimesController.value);
          break;
        case 1:
          _stopTimesController.add(_stopTimesController.value + newStopTimes);
          break;
      }
    });
  }

  void onArrivalStationSelected(Station station) {
    setState(() {
      arrivalStation = station;
      minusOffset = stop_time_offset.Offset(direction: 0);
      plusOffset = stop_time_offset.Offset(direction: 0);
    });
    updateStopTimes(0);
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _stopTimesController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.station.name;

    if (arrivalStation != null) {
      title += ' > ${arrivalStation!.name}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(children: [
        if (arrivalStation == null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: StationSearchWidget(
                resultCount: 3,
                onStationSelected: onArrivalStationSelected,
                onlySource: widget.station.source,
                hideIds: [widget.station.id],
                scrollController: _scrollController),
          ),
        Expanded(
            child: (minusOffset != null)
                ? CustomMaterialIndicator(
                    onRefresh: () async {
                      updateStopTimes(-1);
                    },
                    indicatorBuilder: (build, controller) {
                      return const Icon(
                        Icons.arrow_upward,
                        color: Colors.blue,
                        size: 30,
                      );
                    },
                    child: _buildListView(),
                  )
                : _buildListView()),
      ]),
    );
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget getListTile(StopTime stopTime) {
    return ListTile(
      leading: Text(
        DateFormat('HH:mm').format(stopTime.schedDepDt!),
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
        ),
      ),
      title: Text(
        '${stopTime.routeName} ${stopTime.destText}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              '#${stopTime.number}',
              textAlign: TextAlign.left,
            ),
          ),
          if (stopTime.platform != null && stopTime.platform!.isNotEmpty)
            Expanded(
              child: Text(
                'Platform ${stopTime.platform}',
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }

  Widget _buildListView() {
    return StreamBuilder<List<StopTime>>(
      stream: _stopTimesController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final stopTimes = snapshot.data!;

          return ListView.builder(
            restorationId: 'StationDetailsView',
            itemCount: stopTimes.length,
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            itemBuilder: (BuildContext context, int index) {
              final stopTime = stopTimes[index];
              final prevStopTime = index > 0 ? stopTimes[index - 1] : null;
              if ((index == stopTimes.length - 1 && plusOffset != null)) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (prevStopTime == null ||
                    !isSameDay(
                        stopTime.schedDepDt!, prevStopTime.schedDepDt!)) {
                  return Column(
                    children: [
                      const Divider(indent: 0),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          DateFormat('EEEE d MMM').format(stopTime.schedDepDt!),
                          style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      getListTile(stopTime),
                    ],
                  );
                } else {
                  return getListTile(stopTime);
                }
              }
            },
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
