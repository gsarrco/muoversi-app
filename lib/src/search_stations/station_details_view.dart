import 'package:flutter/material.dart';
import 'package:muoversi/src/models/station.dart';

class StationDetailsView extends StatelessWidget {
  final Station station;

  // also convert station from map

  StationDetailsView({Key? key, required stationMap})
      : station = Station.fromJson(stationMap),
        super(key: key);

  static const routeName = '/station_details';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
      ),
      body: const Center(
        child: Text('More Information Here'),
      ),
    );
  }
}
