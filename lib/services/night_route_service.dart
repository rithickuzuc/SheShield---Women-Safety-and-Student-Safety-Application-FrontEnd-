import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SafetyPoint { const SafetyPoint(this.name, this.type, this.location); final String name, type; final LatLng location; }
class NightRouteResult { const NightRouteResult(this.destination, this.route, this.points, this.distanceKm); final LatLng destination; final List<LatLng> route; final List<SafetyPoint> points; final double distanceKm; }

class NightRouteService {
  static const headers = {'User-Agent': 'SheShield student safety project/1.0'};
  Future<NightRouteResult> route(LatLng start, String query) async {
    final search = await http.get(Uri.https('nominatim.openstreetmap.org', '/search', {'q': query, 'format': 'json', 'limit': '1'}), headers: headers).timeout(const Duration(seconds: 15));
    final list = jsonDecode(search.body) as List;
    if (list.isEmpty) throw Exception('Destination not found.');
    final destination = LatLng(double.parse(list[0]['lat']), double.parse(list[0]['lon']));
    final response = await http.get(Uri.parse('https://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson&alternatives=true')).timeout(const Duration(seconds: 20));
    final routes = (jsonDecode(response.body) as Map<String, dynamic>)['routes'] as List? ?? [];
    if (routes.isEmpty) throw Exception('Route unavailable.');
    final route = routes.reduce((a, b) => (a['distance'] as num) < (b['distance'] as num) ? a : b) as Map<String, dynamic>;
    final points = ((route['geometry'] as Map)['coordinates'] as List).map((p) => LatLng(((p as List)[1] as num).toDouble(), (p[0] as num).toDouble())).toList();
    return NightRouteResult(destination, points, await nearby(start), (route['distance'] as num).toDouble() / 1000);
  }
  Future<List<SafetyPoint>> nearby(LatLng center) async {
    final query = '[out:json];(node(around:3000,${center.latitude},${center.longitude})[amenity=police];node(around:3000,${center.latitude},${center.longitude})[amenity=hospital];node(around:3000,${center.latitude},${center.longitude})[amenity=security_booth];);out 20;';
    try {
      final response = await http.post(Uri.parse('https://overpass-api.de/api/interpreter'), headers: {...headers, 'Content-Type': 'application/x-www-form-urlencoded'}, body: {'data': query}).timeout(const Duration(seconds: 20));
      final elements = (jsonDecode(response.body) as Map)['elements'] as List;
      return elements.map((value) { final item = value as Map<String, dynamic>; final tags = (item['tags'] as Map?) ?? {}; final type = tags['amenity']?.toString() ?? 'security'; return SafetyPoint(tags['name']?.toString() ?? type, type, LatLng((item['lat'] as num).toDouble(), (item['lon'] as num).toDouble())); }).toList();
    } catch (_) { return []; }
  }
}
