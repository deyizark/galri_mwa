import 'package:http/http.dart' as http;
import 'dart:convert';

class APIService {

  static Future<dynamic> get(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw "Gen yon bagay ki pa mache byen !!";
    }
  }
}
