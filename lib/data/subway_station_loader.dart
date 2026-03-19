import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/subway_station.dart';

const seoulStationsAssetPath = 'assets/data/subway/seoul_stations.json';

Future<List<SubwayStation>> loadSeoulStations() async {
  final jsonString = await rootBundle.loadString(seoulStationsAssetPath);
  final decoded = jsonDecode(jsonString) as List<dynamic>;

  return decoded
      .map((item) => SubwayStation.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
}
