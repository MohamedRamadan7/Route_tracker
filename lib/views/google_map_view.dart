import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:route_tracker/model/location_info/lat_lng.dart';
import 'package:route_tracker/model/location_info/location.dart';
import 'package:route_tracker/model/location_info/location_info.dart';
import 'package:route_tracker/model/routes_model/routes_model.dart';
import 'package:uuid/uuid.dart';

import '../model/place_autocomplete_model/place_autocomplete_model.dart';
import '../utils/google_maps_place_service.dart';
import '../utils/location_service .dart';
import '../utils/routes_servies.dart';
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
  late LocationService locationService;
  late TextEditingController textEditingController;
  late PlacesService placesService;
  late RoutesSrevises routesSrevises;
  late Uuid uuid;
  late LatLng currentLocation;
  late LatLng destnation;
  @override
  void initState() {
    uuid = const Uuid();
    placesService = PlacesService();
    routesSrevises = RoutesSrevises();
    textEditingController = TextEditingController();
    initialCameraPosition = const CameraPosition(target: LatLng(0, 0));
    locationService = LocationService();
    fetchPredictions();
    super.initState();
  }

  @override
  void dispose() {
    googleMapController.dispose();
    textEditingController.dispose();
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
            GoogleMap(
                polylines: polyLines,
                markers: markers,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  googleMapController = controller;
                  updateCurrentLocation();
                },
                initialCameraPosition: initialCameraPosition),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  CustomTextField(
                    textEditingController: textEditingController,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  CustomListView(
                    onPlaceSelect: (placeDetailsModel) async {
                      textEditingController.clear();
                      places.clear();

                      sesstionToken = null;
                      destnation = LatLng(
                          placeDetailsModel.geometry!.location!.lat!,
                          placeDetailsModel.geometry!.location!.lng!);
                      var points = await getRouteData();
                      displayRoute(points: points);
                      // var points =
                      //     await mapServices.getRouteData(desintation: desintation);
                      // mapServices.displayRoute(points,
                      //     polyLines: polyLines,
                      //     googleMapController: googleMapController);

                      setState(() {});
                    },
                    places: places,
                    mapServices: placesService,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void updateCurrentLocation() async {
    try {
      LocationData locationData = await locationService.getLocation();
      currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      Marker currentLocationMarker = Marker(
        markerId: MarkerId('my_lcation'),
        position: currentLocation,
      );
      CameraPosition cameraPosition =
          CameraPosition(target: currentLocation, zoom: 16);
      googleMapController
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
      markers.add(currentLocationMarker);
      setState(() {});
    } on LocationServiceException catch (e) {
      print(e);
    } on LocationPermissionException catch (e) {
      print(e);
    } catch (e) {
      print(e);
    }
  }

  void fetchPredictions() {
    textEditingController.addListener(() async {
      sesstionToken ??= uuid.v4();
      if (textEditingController.text.isNotEmpty) {
        List<PlaceAutocompleteModel> results =
            await placesService.getPredictions(
                input: textEditingController.text,
                sesstionToken: sesstionToken!);
        places.clear();
        places.addAll(results);
        setState(() {});
      } else {
        places.clear();
        setState(() {});
      }
    });
  }

  Future<List<LatLng>> getRouteData() async {
    LocationInfoModel origin = LocationInfoModel(
      location: LocationModel(
        latLng: LatLngModel(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude),
      ),
    );
    LocationInfoModel destination = LocationInfoModel(
      location: LocationModel(
        latLng: LatLngModel(
            latitude: destnation.latitude, longitude: destnation.longitude),
      ),
    );
    RoutesModel routes = await routesSrevises.fetchRoutes(
      origin: origin,
      destination: destination,
    );
    List<LatLng> points = getDecodedRoute(routes);
    print(
        "dddddddddddddddddd: ${routes.routes!.first.polyline!.encodedPolyline!}");
    return points;
  }

  List<LatLng> getDecodedRoute(RoutesModel routes) {
    PolylinePoints polylinePoints = PolylinePoints();

    List<PointLatLng> result = polylinePoints
        .decodePolyline(routes.routes!.first.polyline!.encodedPolyline!);
    List<LatLng> points =
        result.map((e) => LatLng(e.latitude, e.longitude)).toList();
    return points;
  }

  void displayRoute({required List<LatLng> points}) {
    Polyline polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: points,
      width: 5,
      color: Colors.blue,
    );
    polyLines.add(polyline);
    setState(() {});
  }
}
