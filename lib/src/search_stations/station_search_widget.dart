import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/models/station.dart';

class StationSearchWidget extends StatefulWidget {
  final int resultCount;
  final Function(Station) onStationSelected;
  final String? onlySource;
  final Station? depStation;
  final ScrollController? scrollController;

  const StationSearchWidget(
      {Key? key,
      required this.resultCount,
      required this.onStationSelected,
      this.onlySource,
      this.depStation,
      this.scrollController})
      : super(key: key);

  @override
  _StationSearchWidgetState createState() => _StationSearchWidgetState();
}

class _StationSearchWidgetState extends State<StationSearchWidget> {
  late Future<List<Station>> stations;
  Timer? _debounce;
  bool showStations = true;

  @override
  void initState() {
    super.initState();
    stations = callApi('');

    widget.scrollController?.addListener(_scrollListener);
  }

  void _scrollListener() {
    bool shouldShowStations =
        widget.scrollController!.position.isScrollingNotifier.value;
    setShowStations(!shouldShowStations);
  }

  Future<List<Station>> callApi(String query) {
    List<String>? hideIds =
        widget.depStation != null ? [widget.depStation!.id] : null;
    return searchStations(
        http.Client(), query, widget.resultCount, widget.onlySource, hideIds);
  }

  void setShowStations(bool show) {
    setState(() {
      showStations = show;
    });
  }

  void updateStations(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() {
        stations = callApi(query);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.scrollController?.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String searchText = widget.onlySource == null
        ? 'Search departing stop/station...'
        : 'Search arrival stop/station...';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PreferredSize(
          preferredSize: const Size.fromHeight(40.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: updateStations,
              onTap: () {
                setShowStations(true);
              },
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              decoration: InputDecoration(
                labelText: searchText,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
            ),
          ),
        ),
        if (showStations)
          Expanded(
            child: FutureBuilder(
              future: stations,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    restorationId: 'SearchStationsListView',
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
                            widget.onStationSelected(station);
                          });
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
      ],
    );
  }
}
