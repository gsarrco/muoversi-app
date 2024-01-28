import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;

import 'helpers/api.dart';
import 'models/source.dart';
import 'models/station_details_arguments.dart';
import 'search_stations/search_stations_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'station_details/station_details_view.dart';

class MyApp extends StatefulWidget {
  final SettingsController settingsController;

  const MyApp({
    super.key,
    required this.settingsController,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Map<String, Source>> sources;

  @override
  void initState() {
    super.initState();
    updateSources();
  }

  void updateSources() {
    setState(() {
      sources = getSourcesFromCity(http.Client(), 'venezia').then(
          (newSources) => {for (var source in newSources) source.name: source});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('it'),
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: widget.settingsController.themeMode,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: widget.settingsController);
                  case StationDetailsView.routeName:
                    final json =
                        routeSettings.arguments as Map<String, dynamic>;
                    final stationDetailsArguments =
                        StationDetailsArguments.fromJson(json);
                    return StationDetailsView(
                      depStation: stationDetailsArguments.depStation,
                      arrStation: stationDetailsArguments.arrStation,
                      sources: sources,
                    );
                  case SearchStationsListView.routeName:
                  default:
                    return SearchStationsListView(sources: sources);
                }
              },
            );
          },
        );
      },
    );
  }
}
