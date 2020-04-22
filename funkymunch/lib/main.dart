import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import "dart:math";

// Main is the starting point for all flutter apps
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RandomRestaurantPicker(),
    );
  }
}

class RandomRestaurantPicker extends StatefulWidget {
  @override
  _RandomRestaurantPickerState createState() => _RandomRestaurantPickerState();
}

class _RandomRestaurantPickerState extends State<RandomRestaurantPicker> {
  int counter = 0;
  final _random = new Random();

  void incrementCounter() {
    setState(() {
      counter++;
    });
  }

  void getRestaurants() async {
    String url = "https://api.yelp.com/v3/businesses/search?location=sunnyvale";
    final yelpApiKey =
        "hZRmj7nxnvZ-Pc8HCxeIxLjsfLIQlKPb7v8i0qwugjqtWg4lPayY6FHBePq1kpeDq0a-CdoPxWfledc9rdg8XYPbU_yVsXgtvHJYjXnmbeWx3POCbwInl3a-0OSfXnYx";
    var response =
        await http.get(url, headers: {"Authorization": "Bearer $yelpApiKey"});
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var businesses = jsonResponse['businesses'];
      print(businesses[_random.nextInt(businesses.length)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('funkymunch'),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(child: Text('$counter')),
            Padding(
              padding: EdgeInsets.all(50),
              child: RaisedButton(
                onPressed: () {
                  getRestaurants();
                },
                child: Text('Click here for a decision'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
