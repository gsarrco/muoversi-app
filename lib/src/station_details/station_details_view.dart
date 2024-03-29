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
import 'package:muoversi/src/station_details/stop_times_list_tile.dart';
import 'package:rxdart/rxdart.dart';

import '../models/source.dart';

class StationDetailsView extends StatefulWidget {
  final Station depStation;
  final Station? arrStation;
  final Future<Map<String, Source>> sources;

  const StationDetailsView({
    Key? key,
    required this.depStation,
    required this.sources,
    this.arrStation,
  }) : super(key: key);

  static const routeName = '/station_details';

  @override
  State<StationDetailsView> createState() => _StationDetailsViewState();
}

class _StationDetailsViewState extends State<StationDetailsView> {
  late BehaviorSubject<List<List<StopTime>>> _stopTimesController;
  late ScrollController _scrollController;
  stop_time_offset.Offset? minusOffset = stop_time_offset.Offset(direction: 0);
  stop_time_offset.Offset? plusOffset = stop_time_offset.Offset(direction: 0);

  @override
  void initState() {
    super.initState();
    _stopTimesController = BehaviorSubject<List<List<StopTime>>>.seeded([]);
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

  void updateStopTimes(int direction, [int limit = 12]) {
    DateTime startDt = DateTime.now();

    stop_time_offset.Offset? offset;
    if (direction == 1) {
      offset = plusOffset;
    }
    if (direction == -1) {
      offset = minusOffset;
    }

    getStopTimes(http.Client(), widget.depStation.ids, widget.depStation.source,
            startDt, offset, limit, widget.arrStation?.ids)
        .then((newStopTimesList) {
      final newDepStopTimes = newStopTimesList.map((e) => e[0]).toList();

      switch (direction) {
        case 0:
          if (newDepStopTimes.isEmpty) {
            minusOffset = null;
          } else {
            minusOffset = createOffset(newDepStopTimes, -1);
          }

          if (newDepStopTimes.length < limit) {
            plusOffset = null;
          } else {
            plusOffset = createOffset(newDepStopTimes, 1);
          }
          break;
        case -1:
          if (newDepStopTimes.length < limit) {
            minusOffset = null;
          } else {
            minusOffset = createOffset(newDepStopTimes, -1);
          }
          break;
        case 1:
          if (newDepStopTimes.length < limit) {
            plusOffset = null;
          } else {
            plusOffset = createOffset(newDepStopTimes, 1);
          }
          break;
      }

      if (newDepStopTimes.isEmpty) {
        minusOffset = null;
        plusOffset = null;
      }

      switch (direction) {
        case 0:
          _stopTimesController.value = newStopTimesList;
          break;
        case -1:
          _stopTimesController
              .add(newStopTimesList + _stopTimesController.value);
          break;
        case 1:
          _stopTimesController
              .add(_stopTimesController.value + newStopTimesList);
          break;
      }
    });
  }

  @override
  void dispose() {
    _stopTimesController.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.depStation.name;

    if (widget.arrStation != null) {
      title += ' > ${widget.arrStation!.name}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(children: [
        if (widget.arrStation == null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: StationSearchWidget(
                resultCount: 3,
                onlySource: widget.depStation.source,
                depStation: widget.depStation,
                scrollController: _scrollController,
                sources: widget.sources),
          ),
        Expanded(
            child: (minusOffset != null)
                ? CustomMaterialIndicator(
                    onRefresh: () async {
                      updateStopTimes(-1, 5);
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

  Widget _buildListView() {
    return StreamBuilder<List<List<StopTime>>>(
      stream: _stopTimesController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final stopTimesList = snapshot.data!;

          return ListView.builder(
            restorationId: 'StationDetailsView',
            itemCount: stopTimesList.length,
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _scrollController,
            itemBuilder: (BuildContext context, int index) {
              final StopTime depStopTime = stopTimesList[index][0];
              final StopTime? prevStopTime =
                  index > 0 ? stopTimesList[index - 1][0] : null;
              final StopTime? arrStopTime = stopTimesList[index].length > 1
                  ? stopTimesList[index][1]
                  : null;

              if ((index == stopTimesList.length - 1 && plusOffset != null)) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (prevStopTime == null ||
                    !isSameDay(
                        depStopTime.schedDepDt!, prevStopTime.schedDepDt!)) {
                  return Column(
                    children: [
                      const Divider(indent: 0),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          DateFormat('EEEE d MMM',
                                  Localizations.localeOf(context).toString())
                              .format(depStopTime.schedDepDt!),
                          style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      StopTimesListTile(
                          depStopTime: depStopTime, arrStopTime: arrStopTime),
                    ],
                  );
                } else {
                  return StopTimesListTile(
                      depStopTime: depStopTime, arrStopTime: arrStopTime);
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
