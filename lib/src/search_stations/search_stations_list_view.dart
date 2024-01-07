import 'package:flutter/material.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:muoversi/src/search_stations/station_search_widget.dart';

import '../settings/settings_view.dart';
import 'station_details_view.dart';

class SearchStationsListView extends StatelessWidget {
  const SearchStationsListView({Key? key}) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    void onStationSelected(Station station) {
      Navigator.restorablePushNamed(
        context,
        StationDetailsView.routeName,
        arguments: station.toJson(),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Muoversi'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.restorablePushNamed(context, SettingsView.routeName);
              },
            ),
          ],
        ),
        body: StationSearchWidget(
          resultCount: 10,
          onStationSelected: onStationSelected, // Pass the callback
        ));
  }
}