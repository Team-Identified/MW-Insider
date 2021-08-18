import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mw_insider/components/loadingCircle.dart';
import 'package:mw_insider/components/nothingAroundBanner.dart';
import 'package:mw_insider/components/objectCard.dart';
import 'package:mw_insider/config.dart';
import 'package:mw_insider/services/backendCommunicationService.dart';
import 'package:mw_insider/services/locationService.dart';
import 'dart:math';
import 'package:provider/provider.dart';



class NearbyObjectsList extends StatefulWidget {
  final void Function(int) onGoToObject;

  NearbyObjectsList({Key key, @required this.onGoToObject}) : super(key: key);

  @override
  _NearbyObjectsListState createState() => _NearbyObjectsListState();
}

class _NearbyObjectsListState extends State<NearbyObjectsList> {
  List<dynamic> nearbyObjects = [];
  bool nothingAround = false;
  var locationData;

  Future<void> loadData() async{
    if (nothingAround)
        return;

    if (!mounted || !isUseful(locationData)) {
      return; // Just do nothing if the widget is disposed.
    }
    Map requestData = {
      "latitude": locationData.latitude,
      "longitude": locationData.longitude,
    };
    Map response = await serverRequest('post', 'geo_objects/get_nearby_objects', requestData);
    if (mounted) {
      setState(() {
        if (response['objects'].length > 0) {
          nearbyObjects = response['objects'];
        }
        else{
          nothingAround = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    locationData = Provider.of<UserLocation>(context);

    if (nearbyObjects == null)
        nearbyObjects = [];

    return ScrollConfiguration(
      behavior: ScrollBehavior(),
      child: GlowingOverscrollIndicator(
        axisDirection: AxisDirection.down,
        color: themeColor,
        child: ListView.separated(
          padding: EdgeInsets.all(0.0),
          shrinkWrap: true,
          physics: ScrollPhysics(),
          itemCount: max(nearbyObjects.length, 1),
          separatorBuilder: (BuildContext context, int index){
            return SizedBox(height: 8.0);
          },
          itemBuilder: (context, index){
            if (nearbyObjects.length > 0) {
              Map currentObject = nearbyObjects[index]['object'];
              String imageUrl = currentObject['image_url'] == null ? animeGirlsUrl : currentObject['image_url'];
              return ObjectCard(
                id: currentObject['id'],
                objectUrl: currentObject['url'],
                distance: nearbyObjects[index]['distance'],
                category: currentObject['category'],
                nameRu: currentObject['name_ru'],
                nameEn: currentObject['name_en'],
                wikiRu: currentObject['wiki_ru'],
                wikiEn: currentObject['wiki_en'],
                imgUrl: imageUrl,
                address: currentObject['address'],
                onGoToObject: widget.onGoToObject,
              );
            }
            else if (!nothingAround){
              loadData();
              return Container(
                child: Column(
                  children: [
                    SizedBox(height: 10.0),
                    LoadingCircle(),
                    SizedBox(height: 15.0),
                  ],
                ),
              );
            }
            else{
              return NothingAroundBanner();
            }
          },
        ),
      ),
    );
  }
}
