import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sheshield/services/location_service.dart';
import 'package:sheshield/services/night_route_service.dart';

class NightSafetyRouteScreen extends StatefulWidget { const NightSafetyRouteScreen({super.key}); @override State<NightSafetyRouteScreen> createState() => _NightSafetyRouteScreenState(); }
class _NightSafetyRouteScreenState extends State<NightSafetyRouteScreen> {
  final destination = TextEditingController(); LatLng? start; NightRouteResult? result; bool loading = true; String? error;
  @override void initState() { super.initState(); locate(); }
  Future<void> locate() async { try { final p = await LocationService().getCurrentPosition(); if (mounted) setState(() { start = LatLng(p.latitude, p.longitude); loading = false; }); } catch (e) { if (mounted) setState(() { error = '$e'; loading = false; }); } }
  Future<void> find() async { if (start == null || destination.text.trim().isEmpty) return; setState(() { loading = true; error = null; }); try { final value = await NightRouteService().route(start!, destination.text.trim()); if (mounted) setState(() => result = value); } catch (e) { if (mounted) setState(() => error = e.toString().replaceFirst('Exception: ', '')); } finally { if (mounted) setState(() => loading = false); } }
  IconData icon(String type) => type == 'police' ? Icons.local_police : type == 'hospital' ? Icons.local_hospital : Icons.security;
  @override void dispose() { destination.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Night Safety Route')), body: Column(children: [
    Padding(padding: const EdgeInsets.all(12), child: Row(children: [Expanded(child: TextField(controller: destination, onSubmitted: (_) => find(), decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.search)))), const SizedBox(width: 8), FilledButton(onPressed: loading ? null : find, child: const Text('Find'))])),
    if (result != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Route: ${result!.distanceKm.toStringAsFixed(1)} km • Safety points: ${result!.points.length}', style: const TextStyle(fontWeight: FontWeight.bold))),
    if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    Expanded(child: loading ? const Center(child: CircularProgressIndicator()) : start == null ? const Center(child: Text('Current location unavailable')) : FlutterMap(options: MapOptions(initialCenter: start!, initialZoom: 14), children: [
      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.sheshield'),
      if (result != null) PolylineLayer(polylines: [Polyline(points: result!.route, strokeWidth: 6, color: const Color(0xFF8E3A62))]),
      MarkerLayer(markers: [Marker(point: start!, width: 48, height: 48, child: const Tooltip(message: 'Starting point', child: Icon(Icons.my_location, color: Colors.blue, size: 34))), if (result != null) Marker(point: result!.destination, width: 48, height: 48, child: const Tooltip(message: 'Destination', child: Icon(Icons.location_pin, color: Colors.red, size: 40))), ...?result?.points.map((p) => Marker(point: p.location, width: 46, height: 46, child: Tooltip(message: '${p.name} (${p.type})', child: Icon(icon(p.type), color: Colors.green, size: 32))))]),
      RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')]),
    ]))
  ]));
}
