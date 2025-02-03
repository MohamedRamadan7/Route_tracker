import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:route_tracker/model/location_info/location_info.dart';
import 'package:route_tracker/model/route_modifiers.dart';
import 'package:route_tracker/model/routes_model/routes_model.dart';

class RoutesSrevises {
  final String baseUrl =
      'https://routes.googleapis.com/directions/v2:computeRoutes';
  final String apiKey = 'AIzaSyD-rAePbrSkmmJGF5liC8S8MF0ZffOxWLY';
  Future<RoutesModel> fetchRoutes(
      {required LocationInfoModel origin,
      required LocationInfoModel destination,
      RouteModifiers? routeModifiers}) async {
    Uri uri = Uri.parse(baseUrl);
    Map<String, String> header = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask':
          'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline'
    };
    Map<String, dynamic> body = {
      "origin": origin.toJson(),
      "destination": destination.toJson(),
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      "computeAlternativeRoutes": false,
      "routeModifiers": routeModifiers != null
          ? routeModifiers.toJson()
          : RouteModifiers().toJson(),
      "languageCode": "en-US",
      "units": "IMPERIAL"
    };
    var response = await http.post(
      uri,
      headers: header,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return RoutesModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Nor routes data ");
    }
  }
}
