import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../models/stop_time.dart';

class StopTimesListTile extends StatelessWidget {
  const StopTimesListTile({
    Key? key,
    required this.depStopTime,
    this.arrStopTime,
  }) : super(key: key);

  final StopTime depStopTime;
  final StopTime? arrStopTime;

  @override
  Widget build(BuildContext context) {
    String? duration;
    if (depStopTime.schedDepDt != null && arrStopTime?.schedArrDt != null) {
      final difference = arrStopTime!.schedArrDt!
          .difference(depStopTime.schedDepDt!)
          .inMinutes;
      final hours = difference ~/ 60;
      final minutes = difference % 60;
      duration = AppLocalizations.of(context)!.duration(hours, minutes);
    }

    String platform = depStopTime.platform ?? '';
    if (arrStopTime != null &&
        arrStopTime!.platform != null &&
        arrStopTime!.platform!.isNotEmpty) {
      platform += ' > ${arrStopTime?.platform}';
    }
    if (platform.isNotEmpty) {
      platform = AppLocalizations.of(context)!.platform(platform);
    }

    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(depStopTime.schedDepDt!),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
              ),
              if (arrStopTime != null)
                Text(
                  ' > ${DateFormat('HH:mm').format(arrStopTime!.schedArrDt!)}',
                  style: const TextStyle(fontSize: 19),
                ),
            ],
          ),
          if (duration != null)
            Text(duration, style: const TextStyle(fontSize: 15)),
        ],
      ),
      title: Text(
        '${depStopTime.routeName} ${depStopTime.destText}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              '#${depStopTime.number}',
              textAlign: TextAlign.left,
            ),
          ),
          if (platform.isNotEmpty)
            Expanded(child: Text(platform, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
