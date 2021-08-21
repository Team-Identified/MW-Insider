import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mw_insider/components/loadingCircle.dart';
import 'package:mw_insider/components/objectCard.dart';
import 'package:mw_insider/config.dart';
import 'package:mw_insider/services/backendCommunicationService.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';


class UserExplorationsList extends StatefulWidget {
  const UserExplorationsList({Key key}) : super(key: key);

  @override
  _UserExplorationsListState createState() => _UserExplorationsListState();
}

class _UserExplorationsListState extends State<UserExplorationsList> {
  bool loading = false, loaded = false;
  List objects = [];

  void loadData() async {
    if (mounted){
      setState(() {
        loading = true;
      });
    }

    Map response = await serverRequest("get", "geo_objects/my_explorations", null);
    if (mounted){
      setState(() {
        objects = response['objects'];
        print(objects);
        loading = false;
        loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    if (!loaded){
      if (!loading)
        loadData();

      return Container(
        child: Column(
          children: [
            Text(
              "Список исследований",
              style: TextStyle(
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 10.0),
            LoadingCircle(),
          ],
        ),
      );
    }
    else{
      if (objects.length > 0){
        return Container(
          height: screenHeight * 0.6,
          width: screenWidth * 0.95,
          child: Neumorphic(
              style: NeumorphicStyle(
                  shape: NeumorphicShape.flat,
                  boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                  depth: -20,
                  intensity: 0.8,
                  lightSource: LightSource.topLeft,
                  color: Colors.white,
              ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              child: ScrollConfiguration(
                behavior: ScrollBehavior(),
                child: GlowingOverscrollIndicator(
                  axisDirection: AxisDirection.down,
                  color: themeColor,
                  child: ListView.separated(
                    padding: EdgeInsets.all(0.0),
                    shrinkWrap: true,
                    physics: ScrollPhysics(),
                    itemCount: max(objects.length + 1, 1),
                    separatorBuilder: (BuildContext context, int index){
                      return SizedBox(height: 8.0);
                    },
                    itemBuilder: (context, index){
                      if (index == 0){
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20.0),
                            Row(
                              children: [
                                SizedBox(width: screenWidth * 0.025),
                                Text(
                                  "Исследованные объекты",
                                  style: TextStyle(
                                    fontSize: 19,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.0),
                            Divider(thickness: 1.5,),
                          ],
                        );
                      }
                      else{
                        index -= 1;
                      }
                      Map currentObject = objects[index];
                      String imageUrl = currentObject['image_url'] == null ? animeGirlsUrl : currentObject['image_url'];
                      return ObjectCard(
                        id: currentObject['id'],
                        objectUrl: currentObject['url'],
                        distance: objects[index]['distance'],
                        category: currentObject['category'],
                        nameRu: currentObject['name_ru'],
                        nameEn: currentObject['name_en'],
                        wikiRu: currentObject['wiki_ru'],
                        wikiEn: currentObject['wiki_en'],
                        imgUrl: imageUrl,
                        address: currentObject['address'],
                        onGoToObject: (int) {},
                      );
                    }
                  ),
                ),
              ),
            ),
          ),
        );
      }
      else{
        return Container(
          child: Column(
            children: [
              Text(
                  "Вы еще ничего не исследовали",
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
              ),
              Text(
                "☹",
                style: TextStyle(
                  fontSize: 35,
                  color: themeColor,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
