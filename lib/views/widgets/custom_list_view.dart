import 'package:flutter/material.dart';
import '../../model/place_autocomplete_model/place_autocomplete_model.dart';
import '../../model/place_details_model/place_details_model.dart';
import '../../utils/google_maps_place_service.dart';

class CustomListView extends StatelessWidget {
  const CustomListView({
    super.key,
    required this.places,
    required this.mapServices,
    required this.onPlaceSelect,
  });

  final List<PlaceAutocompleteModel> places;
  final void Function(PlaceDetailsModel) onPlaceSelect;
  final PlacesService mapServices;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(places[index].description!),
            leading: const Icon(Icons.pin_drop_outlined),
            trailing: IconButton(
              onPressed: () async {
                var placeDetails = await mapServices.getPlaceDetails(
                    sesstionToken: '', placeId: places[index].placeId!);
                onPlaceSelect(placeDetails);
              },
              icon: const Icon(Icons.arrow_circle_right_outlined),
            ),
          );
        },
        separatorBuilder: (context, index) {
          return const Divider(
            height: 0,
          );
        },
        itemCount: places.length,
      ),
    );
  }
}
