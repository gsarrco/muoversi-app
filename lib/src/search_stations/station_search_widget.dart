import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:http/http.dart' as http;
import 'package:muoversi/src/helpers/api.dart';
import 'package:muoversi/src/helpers/search-stations.dart';
import 'package:muoversi/src/models/station.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/source.dart';
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
  State<StationSearchWidget> createState() => _StationSearchWidgetState();
}

class _StationSearchWidgetState extends State<StationSearchWidget> {
  List<StationDetailsArguments> savedArgs = [];
  List<StationDetailsArguments> fetchedArgs = [];
  Timer? _debounce;
  bool showStations = true;
  late SharedPreferences prefs;
  List<StationDetailsArguments> argsList = [];
  bool isLoading = true;
  final TextEditingController queryController = TextEditingController();
  late Future<Map<String, Source>> sources;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_scrollListener);
    sources =
        getSourcesFromCity(http.Client(), 'venezia').then((newSources) => {
              for (var source in newSources) source.name: source,
            });
    initPrefs();
  }

  void initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    if (widget.depStation != null) {
      getRecentsAndSuggestions();
    }
  }

  void getRecentsAndSuggestions([forceUpdate = false]) {
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
    queryController.clear();

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
      callApi(query, widget.resultCount).then((newFetchedArgs) => {
            setState(() {
              fetchedArgs = newFetchedArgs;
              argsList = fetchedArgs;
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

  void goToStationDetails(StationDetailsArguments stationDetailsArguments) {
    // if it is going to station details for the first time
    if (widget.depStation == null) {
      Navigator.restorablePushNamed(
        context,
        StationDetailsView.routeName,
        arguments: stationDetailsArguments.toJson(),
      );
      return;
    }
    // if it is going to station details from arrival station search
    Navigator.restorablePushReplacementNamed(
      context,
      StationDetailsView.routeName,
      arguments: stationDetailsArguments.toJson(),
    );
  }

  void onStationSelected(StationDetailsArguments stationDetailsArguments) {
    final List<String> newPrefList = stationDetailsArguments.getNewPrefList(
      prefs.getStringList('recentArgs') ?? [],
      3,
    );
    prefs.setStringList('recentArgs', newPrefList).then((value) => {
          goToStationDetails(stationDetailsArguments),
        });
  }

  void deleteSavedArg(int index) {
    setState(() {
      argsList.removeAt(index);
    });
    List<String> currentList = prefs.getStringList('recentArgs') ?? [];
    currentList.removeAt(index);
    prefs.setStringList('recentArgs', currentList).then((value) => {
          setState(() {
            getRecentsAndSuggestions(true);
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations? localizations = AppLocalizations.of(context);

    final String searchText = widget.onlySource == null
        ? localizations!.searchDepStation
        : localizations!.searchArrStation;

    Widget getListTile(StationDetailsArguments stationDetailsArguments,
        Map<String, Source>? sources) {
      final depStation = stationDetailsArguments.depStation;
      Source? source = sources?[depStation.source];
      int iconCode = source?.iconCode ?? 0xe3ab;
      String colorHex = source?.color.replaceFirst('#', '0xff') ?? '0xff9e9e9e';
      return ListTile(
          title: Text(
              stationDetailsArguments.getTitle(widget.depStation != null),
              overflow: TextOverflow.ellipsis),
          leading: CircleAvatar(
            backgroundColor: Color(int.parse(colorHex)),
            child: Icon(IconData(iconCode, fontFamily: 'MaterialIcons'),
                color: Colors.white),
          ),
          trailing:
              stationDetailsArguments.saved ? const Icon(Icons.schedule) : null,
          onTap: () {
            onStationSelected(stationDetailsArguments);
          });
    }

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
                controller: queryController,
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
              child: FutureBuilder<Map<String, Source>>(
                  future: sources,
                  builder: (context, snapshot) {
                    if (isLoading || !snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    return ListView.builder(
                      restorationId: 'SearchStationsListView',
                      itemCount: argsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final StationDetailsArguments stationDetailsArguments =
                            argsList[index];

                        if (!stationDetailsArguments.saved) {
                          return getListTile(
                              stationDetailsArguments, snapshot.data);
                        }

                        return Dismissible(
                          key: Key(stationDetailsArguments.depStation.id +
                              index.toString()),
                          direction: DismissDirection.startToEnd,
                          onDismissed: (direction) {
                            deleteSavedArg(index);

                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text(localizations!.recentTripDeleted)));
                          },
                          // Show a red background as the item is swiped away.
                          background: Container(
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: getListTile(
                              stationDetailsArguments, snapshot.data),
                        );
                      },
                    );
                  }),
            ),
        ],
      ),
    );
  }
}
