import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mw_insider/components/userExplorationsList.dart';
import 'package:mw_insider/services/uiService.dart';
import 'package:mw_insider/components/loadingCircle.dart';
import 'package:mw_insider/components/middleButton.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:mw_insider/config.dart';
import 'package:mw_insider/services/backendCommunicationService.dart';


class ProfilePage extends StatefulWidget {
  final VoidCallback onLogOutPressed;

  ProfilePage({@required this.onLogOutPressed});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<ProfilePage> {
  String name, email, rank, dateJoined;
  int id, points;
  List<dynamic> tags;
  bool loaded = false, loading = false;

  TextEditingController _addTagController;
  TextEditingController _removeTagController;

  @override
  void initState() {
    super.initState();
    _addTagController = TextEditingController();
    _removeTagController = TextEditingController();
  }

  void loadData() async {
    if (mounted){
      setState(() {
        loading = true;
      });
    }
    Map resGetUrl = await serverRequest("get", "auth/users/me", null);
    int userId = resGetUrl["id"];
    Map res = await serverRequest("get", "accounts/profile/$userId", null);
    Map data = res["user"];
    if (mounted){
      setState(() {
        id = userId;
        name = data["username"];
        email = data["email"];
        rank = res["rank"];
        points = res["points"];
        dateJoined = DateFormat('EEEE d MMMM H:mm')
            .format(DateTime.parse(data["date_joined"]));
        tags = res["notification_tags"];
        loading = false;
        loaded = true;
      });
    }
  }

  void addTag(String tagValue) async {
    _addTagController.clear();
    if (tagValue.length < 50) {
      Map requestData = {
        'tags': tagValue,
      };
      await serverRequest('post', '/accounts/profile/set_tags', requestData);
      loadData();
    }
  }

  void removeTag(String tagValue) async {
    _removeTagController.clear();
    Map requestData = {
      'tags': tagValue,
    };
    await serverRequest('post', '/accounts/profile/remove_tags', requestData);
    loadData();
  }

  Widget getRankAvatar(double screenWidth){
    return CircleAvatar(
      radius: screenWidth / 6,
      backgroundImage: AssetImage(getRankIconPath(rank)),
      backgroundColor: Colors.black,
    );
  }

  Widget getUserName(){
    return Text(
        '$name',
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 30,
        )
    );
  }

  Widget getDateJoinedCard(){
    return Card(
        color: Colors.white70,
        margin:
        EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: ListTile(
          leading: Icon(
            Icons.cake,
            color: themeColorShade,
          ),
          title: Text(
            dateJoined,
            style:
            TextStyle(
              fontSize: 22,
              color: Colors.black,
            ),
          ),
        )
    );
  }

  Widget getEmailCard(double screenWidth){
    return Container(
      child: Text(
        email,
        style:
        TextStyle(
            fontSize: 17,
        ),
      ),
    );
  }

  Widget getRankInfo(double screenWidth){
    return Container(
      child: Column(
        children: [
          getPointsProgress(screenWidth),
          Text(
            rank,
            style: TextStyle(
              fontSize: 25.0,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget getPointsProgress(double screenWidth){
    List<int> pointsBoundaries = getPointsBoundaries(rank);
    int minPoints = pointsBoundaries[0];
    int maxPoints = pointsBoundaries[1];
    double progressValue = (points - minPoints) / (maxPoints - minPoints + 1);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth / 13),
      child: Column(
        children: [
          Text(
            'Счёт: $points',
            style: TextStyle(
              fontSize: 18.0,
            ),
          ),
          LinearProgressIndicator(
            backgroundColor: Colors.grey,
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            minHeight: 10.0,
            value: progressValue,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$minPoints',
                style: TextStyle(
                  fontSize: 19.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                '${maxPoints + 1}',
                style: TextStyle(
                  fontSize: 19.0,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget getHeader(double screenWidth){
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          getRankAvatar(screenWidth),
          SizedBox(height: 15.0),
          getUserName(),
          Center(child: getEmailCard(screenWidth)),
          SizedBox(height: 20.0),
          getRankInfo(screenWidth),
        ],
      ),
    );
  }

  Widget getTagsWindow(double screenWidth){
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
              "Ваши теги",
              style: TextStyle(
                fontSize: 18.0,
              ),
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          myTags,
          SizedBox(height: 15.0),
          Center(child: addTagField(screenWidth)),
          Center(child: removeTagField(screenWidth)),
        ],
      ),
    );
  }

  Widget addTagField(double screenWidth) {
    return Container(
      width: screenWidth * 0.8,
      child: Theme(
        data: ThemeData(
          primaryColor: themeColor,
        ),
        child: TextField(
          controller: _addTagController,
          onSubmitted: addTag,
          decoration: InputDecoration(
            hintText: "Добавить тег",
            prefixIcon: Icon(Icons.add, color: themeColorShade),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: themeColor, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget removeTagField(double screenWidth) {
    return Container(
      width: screenWidth * 0.8,
      child: Theme(
        data: ThemeData(
          primaryColor: themeColor,
        ),
        child: TextField(
          controller: _removeTagController,
          onSubmitted: removeTag,
          decoration: InputDecoration(
            hintText: "Удалить тег",
            prefixIcon: Icon(Icons.remove, color: themeColorShade),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: themeColor, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget getLogOutButton(){
    return MiddleButton(
      text: "Выйти",
      press: () async {
        await storage.delete(key: "access_jwt");
        await storage.delete(key: "refresh_jwt");
        widget.onLogOutPressed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (loaded){
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                SizedBox(height: 20),
                getHeader(screenWidth),
                SizedBox(height: 10),
                getTagsWindow(screenWidth),
                SizedBox(height: 10),
                getDateJoinedCard(),
                SizedBox(height: 10),
                UserExplorationsList(),
                SizedBox(height: 30.0),
                getLogOutButton(),
              ],
            ),
          ),
        ),
      );
    }
    else{
      if (!loading)
        loadData();
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LoadingCircle(),
                  SizedBox(height: 20.0),
                  Text("Loading", style: TextStyle(fontSize: 20.0),),
                ]
            )
        ),
      );
    }
  }
}
