import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:muoversi/src/models/stop_time.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:http/http.dart' as http;

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
  int offset = 0;
  final int limit = 12;

  @override
  void initState() {
    super.initState();
    _stopTimesController = BehaviorSubject<List<StopTime>>.seeded([]);
    _scrollController = ScrollController();

    updateStopTimes();

    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        updateStopTimes();
      }
    }
  }

  void updateStopTimes() {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());

    getStopTimes(http.Client(), widget.station.ids, widget.station.source, date,
            offset, limit)
        .then((newStopTimes) {
      _stopTimesController.add(_stopTimesController.value + newStopTimes);
      offset += limit;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.name),
      ),
      body: Center(
        child: StreamBuilder<List<StopTime>>(
          stream: _stopTimesController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final stopTimes = snapshot.data!;

              return ListView.builder(
                restorationId: 'StationDetailsView',
                itemCount: stopTimes.length,
                controller: _scrollController,
                itemBuilder: (BuildContext context, int index) {
                  final stopTime = stopTimes[index];
                  if (index == stopTimes.length - 1) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else {
                    return ListTile(
                      leading: Text(
                        DateFormat('HH:mm').format(stopTime.schedDepDt!),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      title: Text(
                        '${stopTime.routeName} ${stopTime.destText}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${stopTime.number}',
                              textAlign: TextAlign.left,
                            ),
                          ),
                          if (stopTime.platform != null &&
                              stopTime.platform!.isNotEmpty)
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
                },
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
