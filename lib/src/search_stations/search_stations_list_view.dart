import 'package:flutter/material.dart';
import 'package:muoversi/src/search_stations/station_search_widget.dart';

import '../settings/settings_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SearchStationsListView extends StatelessWidget {
  const SearchStationsListView({Key? key}) : super(key: key);

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
        body: const StationSearchWidget(
          resultCount: 10, // Pass the callback
        ));
  }
}
