import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mw_insider/components/loadingCircle.dart';
import 'package:mw_insider/services/uiService.dart';


class ObjectCard extends StatelessWidget {
  final int id;
  final String objectUrl;
  final int distance;
  final String category;
  final String nameRu;
  final String nameEn;
  final String wikiRu;
  final String wikiEn;
  final String imgUrl;
  final String address;
  final void Function(int) onGoToObject;

  const ObjectCard({
    this.id,
    this.objectUrl,
    this.distance,
    this.category,
    this.nameRu,
    this.nameEn,
    this.wikiRu,
    this.wikiEn,
    this.imgUrl,
    this.address,
    this.onGoToObject,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: (){
        onGoToObject(id);
      },
      child: Container(
        padding: EdgeInsets.all(5.0),
        child: Container(
          padding: EdgeInsets.fromLTRB(5.0, 5.0, 5.0, 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nameRu,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              Text(
                nameEn,
                style: TextStyle(
                  fontSize: 17.0,
                ),
              ),
              Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            getIcon(category),
                            color: Colors.blueGrey,
                          ),
                          Container(
                            width: screenWidth * 0.6,
                            child: Text(
                              capitalize(getRussianCategory(category)),
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.blueGrey,
                          ),
                          Container(
                            width: screenWidth * 0.6,
                            child: Text(
                              capitalize(address),
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.directions_walk_outlined,
                            color: Colors.blueGrey,
                          ),
                          Container(
                            width: screenWidth * 0.6,
                            child: Text(
                              "${distance.toString()}m",
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 16.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Flexible(
                    child: Container(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace){
                            return Image.asset(
                              'assets/images/AnimeGirls.jpg',
                              fit: BoxFit.cover,
                            );
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
