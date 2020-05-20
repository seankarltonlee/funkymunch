class Business {
  final String name;
  final String imageURL;
  final String latitude;
  final String longitude;
  final String yelpURL;

  Business(
      {this.name, this.yelpURL, this.imageURL, this.latitude, this.longitude});

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
        name: json['name'] as String,
        yelpURL: json['url'] as String,
        imageURL: json['image_url'] as String,
        latitude: json['coordinates']['latitude'].toString(),
        longitude: json['coordinates']['longitude'].toString());
  }
}
