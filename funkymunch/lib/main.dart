import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'dart:math';
import 'dart:io';
import 'dart:async';

// Third party
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// Local files
import 'businesses.dart';

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
        primaryColor: Colors.black,
        textTheme: GoogleFonts.ebGaramondTextTheme(Theme.of(context).textTheme),
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.deepPurpleAccent[700], //  <-- dark color
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
  Image resturantImage = Image.asset('images/thumbsup.webp');

  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  Position currentPosition;
  String latitude;
  String longitude;
  String restaurantLatitude;
  String restaurantLongitude;
  String yelpURL;

  bool showDirections = false;

  // In-app purchases
  final InAppPurchaseConnection _iap = InAppPurchaseConnection.instance;

  /// Products for sale
  List<ProductDetails> _products = [];

  /// Past purchases
  List<PurchaseDetails> _purchases = [];

  /// Updates to purchases
  StreamSubscription<List<PurchaseDetails>> _subscription;

  // number of clicks
  int _credits = 0;

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
    // TODO: Should use a query string generator
    String url =
        "https://api.yelp.com/v3/businesses/search?limit=50&term=food&radius=10000&open_now=true&latitude=$latitude&longitude=$longitude";
    final yelpApiKey =
        "hZRmj7nxnvZ-Pc8HCxeIxLjsfLIQlKPb7v8i0qwugjqtWg4lPayY6FHBePq1kpeDq0a-CdoPxWfledc9rdg8XYPbU_yVsXgtvHJYjXnmbeWx3POCbwInl3a-0OSfXnYx";
    var response =
        await http.get(url, headers: {"Authorization": "Bearer $yelpApiKey"});
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var businesses = jsonResponse['businesses'];
      return businesses;
    }
    // TODO: Add some error handling
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

  Future<void> _getCurrentLocation() async {
    Position position = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
    print("Getting position");
    print(position);
    setState(() {
      currentPosition = position;
      latitude = currentPosition.latitude.toString();
      longitude = currentPosition.longitude.toString();
    });
  }

  void getRandomBusiness() {
    var randomBusiness = businessNames[_random.nextInt(businessNames.length)];
    setState(() {
      randomName = randomBusiness.name;
      yelpURL = randomBusiness.yelpURL;
      restaurantLatitude = randomBusiness.latitude;
      restaurantLongitude = randomBusiness.longitude;
      introMessage = 'You should eat at ${randomName}';
      resturantImage =
          Image.network(randomBusiness.imageURL, fit: BoxFit.fitWidth);
      showDirections = true;
    });
  }

  /// Initialize data
  void _initialize() async {
    // Check availability of In App Purchases
    var _available = await _iap.isAvailable();
    print(_available);
    if (_available) {
      await _getProducts();
      await _getPastPurchases();

      // Verify and deliver a purchase with your own business logic
      _verifyPurchase();

      // Listen to new purchases
      setState(() {
        _subscription = _iap.purchaseUpdatedStream.listen(
          (data) => setState(
            () {
              print('NEW PURCHASE');
              _purchases.addAll(data);
              _verifyPurchase();
            },
          ),
          onError: (error) {
            print(error);
          },
        );
      });
    }
  }

  /// Purchase a product
  /// Purchase a product
  void _buyProduct(ProductDetails prod) {
    print(prod);
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: prod,
        sandboxTesting: true,
      );
      // For one time purchase
      print(purchaseParam.productDetails.id);
      print(purchaseParam.productDetails.price);
      print(purchaseParam.productDetails.title);
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
      print('purchase successful');
    } catch (e) {
      print(e);
    }
  }

  /// Get all products available for sale
  Future<void> _getProducts() async {
    Set<String> ids = Set.from(['FunkymunchSubscription', 'test_a']);
    ProductDetailsResponse response = await _iap.queryProductDetails(ids);

    setState(() {
      _products = response.productDetails;

      print(_products[0].description);
    });
  }

  /// Gets past purchases
  Future<void> _getPastPurchases() async {
    QueryPurchaseDetailsResponse response = await _iap.queryPastPurchases();

    for (PurchaseDetails purchase in response.pastPurchases) {
      if (Platform.isIOS) {
        InAppPurchaseConnection.instance.completePurchase(purchase);
      }
    }

    setState(() {
      _purchases = response.pastPurchases;
    });
  }

  /// Returns purchase of specific product ID
  PurchaseDetails _hasPurchased(String productID) {
    return _purchases.firstWhere((purchase) => purchase.productID == productID,
        orElse: () => null);
  }

  /// Your own business logic to setup a consumable
  void _verifyPurchase() {
    PurchaseDetails purchase = _hasPurchased('FunkymunchSubscription');

    // TODO serverside verification & record consumable in the database

    if (purchase != null && purchase.status == PurchaseStatus.purchased) {
      setState(() {
        _credits = 10;
      });
    }
  }

  @override
  void initState() {
    // init
    super.initState();
    _initialize();

    _getCurrentLocation().then((x) {
      getBusinessNames();
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.only(top: 35.0),
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
              padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 50.0),
              child: Container(
                margin: EdgeInsets.only(bottom: 50.0),
                child: RaisedButton(
                  onPressed: () {
                    getRandomBusiness();
                  },
                  elevation: 7.0,
                  padding: EdgeInsets.all(20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35.0),
                    side: BorderSide(color: Colors.red),
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 50.0),
              child: Container(
                margin: EdgeInsets.only(bottom: 20.0),
                child: RaisedButton(
                  onPressed: () {
                    _buyProduct(_products[0]);
                  },
                  elevation: 7.0,
                  padding: EdgeInsets.all(20.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35.0),
                    side: BorderSide(color: Colors.red),
                  ),
                  child: Text(
                    'Buy credits',
                    style: GoogleFonts.roboto(
                      fontSize: 28.0,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              "$_credits",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "$_subscription",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "$_products",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
