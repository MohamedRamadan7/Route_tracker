import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/place_autocomplete_model/place_autocomplete_model.dart';

class PlacesService {
  final String baseUrl = 'https://maps.googleapis.com/maps/api/place';
  final String apiKey = 'AIzaSyD-rAePbrSkmmJGF5liC8S8MF0ZffOxWLY';
  Future<List<PlaceAutocompleteModel>> getPredictions(
      {required String input, required String sesstionToken}) async {
    var response = await http.get(Uri.parse(
        '$baseUrl/autocomplete/json?key=$apiKey&input=$input&sessiontoken=$sesstionToken'));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body)['predictions'];
      List<PlaceAutocompleteModel> places = [];
      data.forEach((item) => places.add(PlaceAutocompleteModel.fromJson(item)));
      return places;
    } else {
      throw Exception();
    }
  }
}
