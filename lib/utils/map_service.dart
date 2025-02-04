import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../model/location_info/lat_lng.dart';
import '../model/location_info/location.dart';
import '../model/location_info/location_info.dart';
import '../model/place_autocomplete_model/place_autocomplete_model.dart';
import '../model/place_details_model/place_details_model.dart';
import '../model/routes_model/routes_model.dart';
import 'location_service .dart';
import 'place_service.dart';
import 'routes_servies.dart';

class MapServices {
  PlacesService placesService = PlacesService();
  LocationService locationService = LocationService();
  RoutesSrevises routesSrevises = RoutesSrevises();

  LatLng? currentLocation;
  Future<void> getPredictions(
      {required String input,
      required String sesstionToken,
      required List<PlaceAutocompleteModel> places}) async {
    if (input.isNotEmpty) {
      var result = await placesService.getPredictions(
          sesstionToken: sesstionToken, input: input);

      places.clear();
      places.addAll(result);
    } else {
      places.clear();
    }
  }

  Future<List<LatLng>> getRouteData({required LatLng desintation}) async {
    LocationInfoModel origin = LocationInfoModel(
      location: LocationModel(
          latLng: LatLngModel(
        latitude: currentLocation!.latitude,
        longitude: currentLocation!.longitude,
      )),
    );
    LocationInfoModel destination = LocationInfoModel(
      location: LocationModel(
          latLng: LatLngModel(
        latitude: desintation.latitude,
        longitude: desintation.longitude,
      )),
    );
    RoutesModel routes = await routesSrevises.fetchRoutes(
        origin: origin, destination: destination);
    PolylinePoints polylinePoints = PolylinePoints();
    List<LatLng> points = getDecodedRoute(polylinePoints, routes);
    return points;
  }

  List<LatLng> getDecodedRoute(
      PolylinePoints polylinePoints, RoutesModel routes) {
    List<PointLatLng> result = polylinePoints.decodePolyline(
      routes.routes!.first.polyline!.encodedPolyline!,
    );

    List<LatLng> points =
        result.map((e) => LatLng(e.latitude, e.longitude)).toList();
    return points;
  }

  void displayRoute(
      {required List<LatLng> points,
      required Set<Polyline> polyLines,
      required GoogleMapController googleMapController}) {
    Polyline route = Polyline(
      color: Colors.blue,
      width: 5,
      polylineId: const PolylineId('route'),
      points: points,
    );

    polyLines.add(route);

    LatLngBounds bounds = getLatLngBounds(points);
    googleMapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 32));
  }

  LatLngBounds getLatLngBounds(List<LatLng> points) {
    var southWestLatitude = points.first.latitude;
    var southWestLongitude = points.first.longitude;
    var northEastLatitude = points.first.latitude;
    var northEastLongitude = points.first.longitude;

    for (var point in points) {
      southWestLatitude = min(southWestLatitude, point.latitude);
      southWestLongitude = min(southWestLongitude, point.longitude);
      northEastLatitude = max(northEastLatitude, point.latitude);
      northEastLongitude = max(northEastLongitude, point.longitude);
    }

    return LatLngBounds(
        southwest: LatLng(southWestLatitude, southWestLongitude),
        northeast: LatLng(northEastLatitude, northEastLongitude));
  }

  void getCurrentLocation(
      {required GoogleMapController googleMapController,
      required Set<Marker> markers,
      required Function onUpdatecurrentLocation}) async {
    var location = await locationService.getLocation();
    currentLocation = LatLng(location.latitude!, location.longitude!);
    Marker currentLocationMarker = Marker(
      markerId: const MarkerId('my_location'),
      position: currentLocation!,
    );
    CameraPosition myCurrentCameraPoistion = CameraPosition(
      target: currentLocation!,
      zoom: 17,
    );
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(myCurrentCameraPoistion));
    markers.add(currentLocationMarker);
    onUpdatecurrentLocation();
  }

  void updateCurrentLocation(
      {required GoogleMapController googleMapController,
      required Set<Marker> markers,
      required Function onUpdatecurrentLocation}) {
    locationService.getRealTimeLocationData((locationData) {
      currentLocation = LatLng(locationData.latitude!, locationData.longitude!);

      Marker currentLocationMarker = Marker(
        markerId: const MarkerId('my_location'),
        position: currentLocation!,
      );
      CameraPosition myCurrentCameraPoistion = CameraPosition(
        target: currentLocation!,
        zoom: 17,
      );
      googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(myCurrentCameraPoistion));
      markers.add(currentLocationMarker);
      onUpdatecurrentLocation();
    });
  }

  Future<PlaceDetailsModel> getPlaceDetails({required String placeId}) async {
    return await placesService.getPlaceDetails(placeId: placeId);
  }
}
