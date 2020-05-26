import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'dart:math';
import 'dart:async';

// Third party
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:transparent_image/transparent_image.dart';

// Local files
import 'businesses.dart';
import 'revenuecat.dart';

// Main is the starting point for all flutter apps
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RandomRestaurantPicker(),
      theme: ThemeData(
        primaryColor: Colors.redAccent,
        textTheme: GoogleFonts.ebGaramondTextTheme(Theme.of(context).textTheme),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.yellowAccent[700], //  <-- dark color
          textTheme:
              ButtonTextTheme.primary, //  <-- this auto selects the right color
        ),
      ),
    );
  }
}

class RandomRestaurantPicker extends StatefulWidget {
  @override
  _RandomRestaurantPickerState createState() => _RandomRestaurantPickerState();
}

class _RandomRestaurantPickerState extends State<RandomRestaurantPicker> {
  final _random = new Random();
  List<dynamic> businessNames;
  String randomName;
  String introMessage = "";
  dynamic resturantImage = Image.asset('images/thumbsup.webp');

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position currentPosition;
  String latitude;
  String longitude;
  String restaurantLatitude;
  String restaurantLongitude;
  String yelpURL;
  bool showDirections = false;

  PayClient payClient = PayClient();
  int coins = 0;
  var offerings;

  AudioCache audioCache = AudioCache();

  // Futurebuilder stuff
  Future _currentLocation;

  Future<void> launchMapsURL() async {
    String mapsURL =
        'https://www.google.com/maps/search/?api=1&query=$restaurantLatitude,$restaurantLongitude';
    if (await canLaunch(mapsURL)) {
      await launch(mapsURL, forceWebView: false);
    } else {
      throw 'Could not launch $mapsURL';
    }
  }

  Future<void> launchYelpURL() async {
    if (await canLaunch(yelpURL)) {
      await launch(yelpURL, forceWebView: false);
    } else {
      throw 'Could not launch $yelpURL';
    }
  }

  Future<dynamic> getRestaurants() async {
    var queryParameters = {
      'limit': '50',
      'radius': '10000',
      'open_now': 'true',
      'latitude': '$latitude',
      'longitude': '$longitude'
    };
    var uri =
        Uri.https('api.yelp.com', '/v3/businesses/search', queryParameters);
    final yelpApiKey =
        "hZRmj7nxnvZ-Pc8HCxeIxLjsfLIQlKPb7v8i0qwugjqtWg4lPayY6FHBePq1kpeDq0a-CdoPxWfledc9rdg8XYPbU_yVsXgtvHJYjXnmbeWx3POCbwInl3a-0OSfXnYx";
    var response =
        await http.get(uri, headers: {"Authorization": "Bearer $yelpApiKey"});
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var businesses = jsonResponse['businesses'];
      return businesses;
    }
    // TODO: Add some error handling
  }

  @override
  void initState() {
    // init
    super.initState();
    setState(() {
      payClient.getOfferings().then((x) {
        print('calling from main');
        print(x);
        offerings = x;
      });
    });
    _currentLocation = _getCurrentLocation().then((x) {
      getBusinessNames();
    });
  }

  void getBusinessNames() {
    setState(() {
      getRestaurants().then((businesses) {
        businesses = businesses as List;
        businessNames =
            businesses.map((business) => Business.fromJson(business)).toList();
      });
    });
  }

  Future _getCurrentLocation() async {
    Position position = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    print("Getting position");
    print(position);
    setState(() {
      currentPosition = position;
      latitude = currentPosition.latitude.toString();
      longitude = currentPosition.longitude.toString();
    });
    return position;
  }

  void showSubscriptionOffering() {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            height: MediaQuery.of(context).size.height * .75,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text("Edit Traip"),
                      // Spacer takes up width between these widgets in a row
                      Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.cancel,
                          color: Colors.orange,
                          size: 25,
                        ),
                        onPressed: () {
                          // Pops widget off, since it's just another widget on top of our view
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 30.0, horizontal: 50.0),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 50.0),
                          child: RaisedButton(
                            onPressed: () {
                              payClient.makePurchase(
                                  offerings.current.availablePackages[0]);
                            },
                            elevation: 7.0,
                            padding: EdgeInsets.all(20.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(35.0),
                            ),
                            child: Text(
                              'Subscribe Now',
                              style: GoogleFonts.roboto(
                                fontSize: 24.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }

  void getRandomBusiness() {
    var randomBusiness = businessNames[_random.nextInt(businessNames.length)];
    setState(() {
      randomName = randomBusiness.name;
      yelpURL = randomBusiness.yelpURL;
      restaurantLatitude = randomBusiness.latitude;
      restaurantLongitude = randomBusiness.longitude;
      introMessage = 'You should eat at \n ${randomName}';
      resturantImage = FadeInImage.memoryNetwork(
        placeholder: kTransparentImage,
        image: randomBusiness.imageURL,
        fadeInDuration: const Duration(milliseconds: 300),
      );
      showDirections = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'funkymunch',
          style: GoogleFonts.righteous(
            letterSpacing: 10.0,
            fontSize: 36.0,
          ),
        ),
        elevation: 7.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SafeArea(
          child: FutureBuilder(
        future: _currentLocation,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              return Text('active');
            case ConnectionState.waiting:
              return Container(
                child: Center(
                  child: SpinKitCubeGrid(
                    color: Colors.redAccent,
                    size: 100.0,
                  ),
                ),
              );
            case ConnectionState.none:
              return Text('none');
            case ConnectionState.done:
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(top: 15.0),
                      child: resturantImage,
                    ),
                  ),
                  Padding(
                      padding: EdgeInsets.all(15),
                      child: Text(
                        introMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(height: 1.5, fontSize: 30),
                      )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Visibility(
                        visible: showDirections,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: FlatButton(
                            onPressed: () {
                              launchMapsURL();
                            },
                            child: Text(
                              'Get directions',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: showDirections,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15.0),
                          child: FlatButton(
                            onPressed: () {
                              launchYelpURL();
                            },
                            child: Text(
                              'See menu',
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 30.0, horizontal: 50.0),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 50.0),
                      child: RaisedButton(
                        onPressed: () {
                          audioCache.play("button-3.mp3");
                          if (coins < 3) {
                            getRandomBusiness();
                            setState(() {
                              coins++;
                            });
                          } else {
                            showSubscriptionOffering();
                          }
                        },
                        elevation: 7.0,
                        padding: EdgeInsets.all(20.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35.0),
                        ),
                        child: Text(
                          'Suprise me!',
                          style: GoogleFonts.roboto(
                            fontSize: 28.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            default:
              return Text('default');
          }
        },
      )),
    );
  }
}
