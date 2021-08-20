import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:mw_insider/components/loadingCircle.dart';
import 'package:mw_insider/components/objectMenu.dart';
import 'package:mw_insider/config.dart';
import 'package:mw_insider/services/backendCommunicationService.dart';
import 'package:mw_insider/services/geoService.dart';
import 'package:mw_insider/services/locationService.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:mw_insider/services/uiService.dart';
import 'package:mw_insider/services/urlLauncherService.dart';
import 'package:provider/provider.dart';


class ObjectPage extends StatefulWidget {
  final int objectId;
  final VoidCallback onGoBack;

  ObjectPage({Key key, @required this.objectId, @required this.onGoBack}) : super(key: key);

  @override
  _ObjectPageState createState() => _ObjectPageState();
}

class _ObjectPageState extends State<ObjectPage> {
  Map objectData;

  void loadData() async {
    Map response = await serverRequest('get', 'geo_objects/geo_object_retrieve/${widget.objectId}', null);
    response['image_url'] = response['image_url'] == null ? animeGirlsUrl : response['image_url'];
    setState(() {
      objectData = response;
    });
  }

  Widget getTagsWindow(double screenWidth){
    List tags = objectData['tags'];

    String tagsLine = "";
    int maxTags = 100;
    for (int i = 0; i < min(tags.length, maxTags); ++i){
      tagsLine += "${tags[i]}";
      if (i < tags.length - 1)
        tagsLine += ', ';
    }
    if (tags.length > maxTags)
      tagsLine += "...";

    Widget myTags;
    if (tags.length > 0){
      myTags = Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tagsLine,
              style: TextStyle(
                color: themeColorShade,
              ),
            ),
          ],
        ),
      );
    }
    else{
      myTags = Container(
        child: Center(
          child: Text(
            "У вас пока нет тегов",
            style: TextStyle(
              fontSize: 17.0,
            ),
          ),
        ),
      );
    }

    return Container(
      child: myTags,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (objectData == null){
      loadData();
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.grey[300],
          body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingCircle(),
                  SizedBox(height: 20.0),
                  Text("Loading", style: TextStyle(fontSize: 20.0),),
                ]
            ),
          ),
        ),
      );
    }
    else {
      double screenWidth = MediaQuery.of(context).size.width;
      double screenHeight = MediaQuery.of(context).size.height;
      var locationData = Provider.of<UserLocation>(context);

      int distance = calculateDistance(
          locationData.latitude,
          locationData.longitude,
          objectData['latitude'],
          objectData['longitude'],
      );

      final String internetSearchQuery = "https://www.google.com/search?q=Москва ${getRussianCategory(objectData['category'])} ${objectData['name_ru']}";

      List<Widget> dataButtons = [];
      if (objectData['wiki_en'] != null){
        dataButtons.add(
          Ink(
            decoration: ShapeDecoration(
              color: themeColor,
              shape: CircleBorder(),
            ),
            child: IconButton(
              onPressed: () {
                tryLaunch(objectData['wiki_en']);
              },
              icon: Icon(MdiIcons.wikipedia, size: 45.0,),
              color: Colors.white,
              iconSize: 60.0,
              padding: EdgeInsets.all(0.0),
              splashColor: themeColor,
            ),
          ),
        );
      }
      if (objectData['wiki_ru'] != null){
        dataButtons.add(
          Ink(
            decoration: ShapeDecoration(
              color: themeColor,
              shape: CircleBorder(),
            ),
            child: IconButton(
              onPressed: () {
                tryLaunch(objectData['wiki_ru']);
              },
              icon: Icon(MdiIcons.alphaB, size: 55.0,),
              color: Colors.white,
              iconSize: 60.0,
              padding: EdgeInsets.all(0.0),
              splashColor: themeColor,
            ),
          ),
        );
      }
      dataButtons.add(
        Ink(
          decoration: ShapeDecoration(
            color: themeColor,
            shape: CircleBorder(),
          ),
          child: IconButton(
            onPressed: () {
              tryLaunch(internetSearchQuery);
            },
            icon: Icon(MdiIcons.searchWeb, size: 45.0,),
            color: Colors.white,
            iconSize: 60.0,
            padding: EdgeInsets.all(0.0),
            splashColor: themeColor,
          ),
        ),
      );

      String explorationStatus = "Не исследовано";
      Widget explorationIcon = Icon(MdiIcons.closeOutline, color: Colors.red, size: 30.0);
      if (objectData['explored']){
        explorationStatus = "Исследован";
        explorationIcon = Icon(MdiIcons.checkOutline, color: Colors.green, size: 30.0);
      }

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: screenWidth,
                        height: screenHeight * 0.4,
                        color: Colors.grey,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: Image.network(
                            objectData['image_url'],
                            errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace){
                              return Image.asset('assets/images/AnimeGirls.jpg');
                            },
                            loadingBuilder: (context, child, progress){
                              return progress == null
                                  ? child
                                  : Container(
                                color: Colors.grey[300],
                                padding: EdgeInsets.symmetric(vertical: 50.0, horizontal: 0.0),
                                child: Center(
                                  child: LoadingCircle(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10.0,
                        top: 8.0,
                        child: ObjMenu(objectId: widget.objectId),
                      ),
                      Positioned(
                        top: 3.0,
                        left: 10.0,
                        child: Container(
                          child: ElevatedButton(
                            child: Icon(Icons.arrow_left, color: Colors.white, size: 27.0,),
                            onPressed: widget.onGoBack,
                            style: ElevatedButton.styleFrom(
                              primary: Colors.black.withOpacity(0.3),
                              elevation: 5,
                              shadowColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
                          child: Container(
                            width: screenWidth,
                            color: themeColor,
                            child: Row(
                              children: [
                                SizedBox(width: 20.0),
                                Container(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 10.0),
                                      Container(
                                        width: screenWidth - 40.0,
                                        child: Text(
                                          objectData['name_ru'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 23.0,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: screenWidth - 40.0,
                                        child: Text(
                                          objectData['name_en'],
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 19.0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.0),
                                      Row(
                                        children: [
                                          Icon(
                                            getIcon(objectData['category']),
                                            color: Colors.white,
                                          ),
                                          Container(
                                            width: screenWidth * 0.6,
                                            child: Text(
                                              capitalize(getRussianCategory(objectData['category'])),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w300,
                                                fontSize: 16.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10.0),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.0),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: dataButtons,
                    ),
                  ),
                  Divider(),
                  Container(
                    child: Row(
                      children: [
                        SizedBox(width: 10.0),
                        explorationIcon,
                        Text(
                          explorationStatus,
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      SizedBox(width: 10.0),
                      Icon(
                        Icons.location_on,
                        size: 30.0,
                        color: Colors.blueGrey,
                      ),
                      Container(
                        width: screenWidth - 60.0,
                        child: Text(
                          capitalize(objectData['address']),
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: 10.0),
                      Icon(
                        Icons.directions_walk_outlined,
                        size: 30.0,
                        color: Colors.blueGrey,
                      ),
                      Container(
                        width: screenWidth - 60.0,
                        child: Text(
                          "${distance}m",
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  getTagsWindow(screenWidth),
                  Container(
                    height: screenHeight * 0.3,
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      child: FlutterMap(
                        options: MapOptions(
                          bounds: LatLngBounds(LatLng(locationData.latitude, locationData.longitude), LatLng(objectData['latitude'], objectData['longitude'])),
                          boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(20.0))
                        ),
                        layers: [
                          TileLayerOptions(
                              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: ['a', 'b', 'c']
                          ),
                          MarkerLayerOptions(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(locationData.latitude, locationData.longitude),
                                builder: (ctx) =>
                                    Container(
                                      child: Icon(Icons.location_on, color: Colors.redAccent, size: 40.0,),
                                    ),
                              ),
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(objectData['latitude'], objectData['longitude']),
                                builder: (ctx) =>
                                    Container(
                                      child: Icon(getIcon(objectData['category']), color: themeColor, size: 40.0,),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
