import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:http/http.dart' as http;
import 'package:muoversi/src/helpers/search-stations.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station_details_arguments.dart';
import '../station_details/station_details_view.dart';

class StationSearchWidget extends StatefulWidget {
  final int resultCount;
  final String? onlySource;
  final Station? depStation;
  final ScrollController? scrollController;

  const StationSearchWidget(
      {Key? key,
      required this.resultCount,
      this.onlySource,
      this.depStation,
      this.scrollController})
      : super(key: key);

  @override
  _StationSearchWidgetState createState() => _StationSearchWidgetState();
}

class _StationSearchWidgetState extends State<StationSearchWidget> {
  List<StationDetailsArguments> savedArgs = [];
  List<StationDetailsArguments> fetchedArgs = [];
  Timer? _debounce;
  bool showStations = true;
  late SharedPreferences prefs;
  List<StationDetailsArguments> argsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_scrollListener);
    initPrefs();
  }

  void initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    if (widget.depStation != null) {
      getRecentsAndSuggestions();
    }
  }

  void getRecentsAndSuggestions([forceUpdate = false]) {
    isLoading = true;
    // for arrival station search, don't include recent args
    if (widget.depStation != null) {
      callApi('', widget.resultCount).then((newFetchedArgs) => {
            setState(() {
              fetchedArgs = newFetchedArgs;
              argsList = fetchedArgs;
              isLoading = false;
            })
          });
      return;
    }

    // for departure station search, include recent args
    final List<String> recentArgs = prefs.getStringList('recentArgs') ?? [];
    final newSavedArgs = recentArgs
        .map((arg) => StationDetailsArguments.fromJsonString(arg, true))
        .toList();

    if (setEquals(savedArgs.toSet(), newSavedArgs.toSet()) &&
        fetchedArgs.isNotEmpty &&
        !forceUpdate) {
      setState(() {
        savedArgs = newSavedArgs;
        argsList = savedArgs + fetchedArgs;
        isLoading = false;
      });
      return;
    }

    // only hide the saved args that have arrStation null
    List<String> extraHideIds = newSavedArgs
        .where((arg) => arg.arrStation == null)
        .map((arg) => arg.depStation.id)
        .toList();

    callApi('', widget.resultCount - newSavedArgs.length, extraHideIds)
        .then((newFetchedArgs) => {
              setState(() {
                savedArgs = newSavedArgs;
                fetchedArgs = newFetchedArgs;
                argsList = savedArgs + fetchedArgs;
                isLoading = false;
              })
            });
  }

  void _scrollListener() {
    bool shouldShowStations =
        widget.scrollController!.position.isScrollingNotifier.value;
    setShowStations(!shouldShowStations);
  }

  Future<List<StationDetailsArguments>> callApi(String query, int slice,
      [List<String>? extraHideIds]) async {
    List<String> hideIds =
        widget.depStation != null ? [widget.depStation!.id] : [];
    if (extraHideIds != null && extraHideIds.isNotEmpty) {
      hideIds = hideIds.isNotEmpty ? hideIds + extraHideIds : extraHideIds;
    }
    final int maxLimit;
    if (widget.depStation == null) {
      // for departure station search
      maxLimit = widget.resultCount;
    } else {
      // for arrival station search
      maxLimit = slice + 1;
    }
    List<Station> stations = await searchStationsAndHide(
        http.Client(), query, maxLimit, slice, widget.onlySource, hideIds);
    if (widget.depStation == null) {
      return stations
          .map((station) => StationDetailsArguments(depStation: station))
          .toList();
    } else {
      return stations
          .map((station) => StationDetailsArguments(
              depStation: widget.depStation!, arrStation: station))
          .toList();
    }
  }

  void setShowStations(bool show) {
    setState(() {
      showStations = show;
    });
  }

  void updateStations(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (query.isEmpty) {
        getRecentsAndSuggestions(true);
        return;
      }
      isLoading = true;
      callApi(query, widget.resultCount).then((newFetchedArgs) => {
            setState(() {
              fetchedArgs = newFetchedArgs;
              argsList = fetchedArgs;
              isLoading = false;
            })
          });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.scrollController?.removeListener(_scrollListener);
    super.dispose();
  }

  void onStationSelected(StationDetailsArguments stationDetailsArguments) {
    final List<String> newPrefList = stationDetailsArguments.getNewPrefList(
      prefs.getStringList('recentArgs') ?? [],
      3,
    );
    prefs.setStringList('recentArgs', newPrefList).then((value) => {
          Navigator.restorablePushNamed(
            context,
            StationDetailsView.routeName,
            arguments: stationDetailsArguments.toJson(),
          )
        });
  }

  @override
  Widget build(BuildContext context) {
    final String searchText = widget.onlySource == null
        ? 'Search departing stop/station...'
        : 'Search arrival stop/station...';
    return FocusDetector(
      onVisibilityGained: () {
        if (widget.depStation == null) {
          getRecentsAndSuggestions();
        }
      },
      child: Column(
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
              child: Builder(builder: (context) {
                if (isLoading) {
                  return const CircularProgressIndicator();
                }

                return ListView.builder(
                  restorationId: 'SearchStationsListView',
                  itemCount: argsList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final StationDetailsArguments stationDetailsArguments =
                        argsList[index];
                    final depStation = stationDetailsArguments.depStation;
                    IconData sourceIcon;
                    Color sourceColor;
                    if (depStation.source == 'treni') {
                      sourceIcon = Icons.train;
                      sourceColor = Colors.green;
                    } else if (depStation.source == 'aut') {
                      sourceIcon = Icons.directions_bus;
                      sourceColor = Colors.orange;
                    } else if (depStation.source == 'nav') {
                      sourceIcon = Icons.directions_boat;
                      sourceColor = Colors.blue;
                    } else {
                      sourceIcon = Icons.location_on;
                      sourceColor = Colors.grey;
                    }

                    return ListTile(
                        title: Text(
                            stationDetailsArguments
                                .getTitle(widget.depStation != null),
                            overflow: TextOverflow.ellipsis),
                        leading: CircleAvatar(
                          backgroundColor: sourceColor,
                          child: Icon(sourceIcon, color: Colors.white),
                        ),
                        trailing: stationDetailsArguments.saved
                            ? const Icon(Icons.schedule)
                            : null,
                        onTap: () {
                          onStationSelected(stationDetailsArguments);
                        });
                  },
                );
              }),
            ),
        ],
      ),
    );
  }
}
