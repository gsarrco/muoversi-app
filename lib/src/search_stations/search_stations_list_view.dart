import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:muoversi/src/search_stations/station_search_widget.dart';

import '../models/source.dart';
import '../settings/settings_view.dart';

class SearchStationsListView extends StatelessWidget {
  final Future<Map<String, Source>> sources;

  const SearchStationsListView({
    Key? key,
    required this.sources,
  }) : super(key: key);

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.appTitle),
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
          sources: sources, // Pass the callback
        ));
  }
}
