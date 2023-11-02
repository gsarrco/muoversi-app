import 'dart:async';

import 'package:flutter/material.dart';
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/models/station.dart';

import '../settings/settings_view.dart';
import 'station_details_view.dart';
import 'package:http/http.dart' as http;

class SearchStationsListView extends StatefulWidget {
  const SearchStationsListView({super.key});

  static const routeName = '/';

  @override
  State<SearchStationsListView> createState() => _SearchStationsListViewState();
}

class _SearchStationsListViewState extends State<SearchStationsListView> {
  late Future<List<Station>> stations;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    stations = searchStations(http.Client(), '', 10);
  }

  void updateStations(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        stations = searchStations(http.Client(), query, 10);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Text('Choose a starting stop:'),
            PreferredSize(
              preferredSize: const Size.fromHeight(40.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: updateStations,
                  decoration: InputDecoration(
                    labelText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
                child: FutureBuilder(
              future: stations,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    restorationId: 'sampleItemListView',
                    itemCount: snapshot.data?.length,
                    itemBuilder: (BuildContext context, int index) {
                      final station = snapshot.data![index];
                      IconData sourceIcon;
                      Color sourceColor;
                      if (station.source == 'treni') {
                        sourceIcon = Icons.train;
                        sourceColor = Colors.green;
                      } else if (station.source == 'aut') {
                        sourceIcon = Icons.directions_bus;
                        sourceColor = Colors.orange;
                      } else if (station.source == 'nav') {
                        sourceIcon = Icons.directions_boat;
                        sourceColor = Colors.blue;
                      } else {
                        sourceIcon = Icons.location_on;
                        sourceColor = Colors.grey;
                      }

                      return ListTile(
                          title: Text(station.name),
                          leading: CircleAvatar(
                            backgroundColor: sourceColor,
                            child: Icon(sourceIcon, color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.restorablePushNamed(
                              context,
                              StationDetailsView.routeName,
                            );
                          });
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            )),
          ],
        ),
      ),
    );
  }
}
