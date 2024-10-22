import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/travel.dart';

class TravelService {
  Future<List<Travel>> fetchTravels() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3001/travels'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Travel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Travels');
    }
  }
}

