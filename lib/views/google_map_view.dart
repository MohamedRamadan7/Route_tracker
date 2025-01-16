import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../model/place_autocomplete_model/place_autocomplete_model.dart';
import '../utils/google_maps_place_service.dart';
import '../utils/location_service .dart';
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
  @override
  void initState() {
    placesService = PlacesService();
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
  List<PlaceAutocompleteModel> places = [];
  LatLng? desintation;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
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

                      // sesstionToken = null;
                      // setState(() {});
                      desintation = LatLng(
                          placeDetailsModel.geometry!.location!.lat!,
                          placeDetailsModel.geometry!.location!.lng!);

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
      LatLng currentPosition =
          LatLng(locationData.latitude!, locationData.longitude!);
      Marker currentLocationMarker = Marker(
        markerId: MarkerId('my_lcation'),
        position: currentPosition,
      );
      CameraPosition cameraPosition =
          CameraPosition(target: currentPosition, zoom: 16);
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
      if (textEditingController.text.isNotEmpty) {
        List<PlaceAutocompleteModel> results =
            await placesService.getPredictions(
                input: textEditingController.text, sesstionToken: '');
        print(results[0].placeId!);
        places.clear();
        places.addAll(results);
        setState(() {});
      } else {
        places.clear();
        setState(() {});
      }
    });
  }
}
