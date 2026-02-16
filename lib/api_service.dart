import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class APIService {
  static const String _apiKey =
      "hTXh78ukeUKPNCVMXM4uRIMGTxb8vYeXCN1JYrm8YQfFIlS6XCh9Rej5";
  static const String _baseUrl = "https://api.pexels.com/v1";

  static Future<dynamic> get(String url) async {
    final response = await http.get(
      Uri.parse("$_baseUrl$url"),
      headers: {"Authorization": _apiKey},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw "Gen yon bagay ki pa mache byen! Status: ${response.statusCode}";
    }
  }

  static Future<List<Photo>> _getPhotos(String endpoint) async {
    final data = await get(endpoint);
    return (data["photos"] as List).map((item) => Photo.fromJson(item)).toList();
  }

  static Future<List<Photo>> getCuratedPhotos({
    int page = 1,
    int perPage = 30,
  }) => _getPhotos("/curated?page=$page&per_page=$perPage");

  static Future<List<Photo>> getAllPhotosByPhotographer(
    String query, {
    int page = 1,
    int perPage = 80,
  }) =>
      _getPhotos("/search?query=$query&page=$page&per_page=$perPage");

  static Future<int> getPhotographerPhotoCount(String query) async {
    final data = await get("/search?query=$query&page=1&per_page=1");
    return data["total_results"] ?? 0;
  }
}
