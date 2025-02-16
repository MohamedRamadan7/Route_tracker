import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';

import '../model/place_autocomplete_model/place_autocomplete_model.dart';
import '../utils/location_service .dart';
import '../utils/map_service.dart';
import 'widgets/custom_list_view.dart';
import 'widgets/custom_text_field.dart';

class GoogleMapView extends StatefulWidget {
  const GoogleMapView({super.key});

  @override
  State<GoogleMapView> createState() => _GoogleMapViewState();
}

class _GoogleMapViewState extends State<GoogleMapView> {
  late CameraPosition initialCameraPosition;
  late GoogleMapController googleMapController;
  late MapServices mapServices;
  late TextEditingController textEditingController;
  late Uuid uuid;
  late LatLng destnation;
  Timer? debouncer;
  @override
  void initState() {
    mapServices = MapServices();
    uuid = const Uuid();
    textEditingController = TextEditingController();
    initialCameraPosition = const CameraPosition(target: LatLng(0, 0));
    fetchPredictions(); // Initialize place predictions
    super.initState();
  }

  @override
  void dispose() {
    googleMapController.dispose();
    textEditingController.dispose();
    debouncer?.cancel();
    super.dispose();
  }

  Set<Marker> markers = {};
  Set<Polyline> polyLines = {};
  List<PlaceAutocompleteModel> places = [];
  String? sesstionToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map widget
            GoogleMap(
                polylines: polyLines,
                markers: markers,
                zoomControlsEnabled: true,
                onMapCreated: (controller) {
                  googleMapController = controller;
                  updateCurrentLocation(); // Fetch and update the current location
                },
                onTap: (LatLng tappedPoint) {
                  markers.removeWhere((marker) =>
                      marker.markerId == const MarkerId('my_location'));
                  mapServices.currentLocation = tappedPoint; // تحديث الوجهة
                  markers.add(
                    Marker(
                      markerId: const MarkerId('my_location'),
                      position: tappedPoint,
                    ),
                  );
                  setState(() {});
                },
                initialCameraPosition: initialCameraPosition),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // Search TextField
                  CustomTextField(
                    textEditingController: textEditingController,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  // List of search predictions
                  CustomListView(
                    onPlaceSelect: (placeDetailsModel) async {
                      textEditingController.clear();
                      places.clear();
                      sesstionToken = null;
                      // Set the destination
                      destnation = LatLng(
                          placeDetailsModel.geometry!.location!.lat!,
                          placeDetailsModel.geometry!.location!.lng!);
                      Marker destnationMarker = Marker(
                        markerId: MarkerId('destnat_location'),
                        position: destnation,
                      );
                      markers.add(destnationMarker);

                      mapServices.getSershLocation(
                          googleMapController: googleMapController,
                          markers: markers,
                          onUpdatecurrentLocation: () {
                            setState(() {});
                          });

                      // Get the route data
                      // var points = await mapServices.getRouteData(
                      //     desintation: destnation);
                      // mapServices.displayRoute(
                      //     points: points,
                      //     polyLines: polyLines,
                      //     googleMapController: googleMapController);

                      setState(() {});
                    },
                    places: places,
                    mapServices: mapServices,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: ElevatedButton(
                onPressed: () {
                  // mapServices.getDirection(
                  //     googleMapController: googleMapController,
                  //     markers: markers,
                  //     onUpdatecurrentLocation: () {
                  //       setState(() {});
                  //     });
                  updateCurrentLocation();
                },
                child: Text('Get Current Location'),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () async {
                  // mapServices.getDirection(
                  //     googleMapController: googleMapController,
                  //     markers: markers,
                  //     onUpdatecurrentLocation: () {
                  //       setState(() {});
                  //     });
                  var points =
                      await mapServices.getRouteData(desintation: destnation);
                  mapServices.displayRoute(
                      points: points,
                      polyLines: polyLines,
                      googleMapController: googleMapController);
                  print(points);
                  setState(() {});
                  // updateCurrentLocation();
                },
                child: Text('Get Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fetches the user's current location and updates the map with a marker
  void updateCurrentLocation() {
    try {
      mapServices.getCurrentLocation(
          markers: markers,
          googleMapController: googleMapController,
          onUpdatecurrentLocation: () {
            setState(() {});
          });
    } on LocationServiceException catch (e) {
      print(e);
    } on LocationPermissionException catch (e) {
      print(e);
    } catch (e) {
      print(e);
    }
  }

  /// Fetches place predictions as the user types in the search field
  void fetchPredictions() {
    textEditingController.addListener(() {
      if (debouncer?.isActive ?? false) debouncer!.cancel();
      debouncer = Timer(
        Duration(milliseconds: 200),
        () async {
          sesstionToken ??= uuid.v4();
          await mapServices.getPredictions(
              input: textEditingController.text,
              sesstionToken: sesstionToken!,
              places: places);
          setState(() {});
        },
      );
    });
  }
}
