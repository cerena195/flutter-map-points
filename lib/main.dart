import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Points Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;


  Future<void> _savePoint(
      String nom,
      LatLng point,
      ) async {
    await firestore.collection('points').add({
      'nom': nom,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'date': Timestamp.now(),
    });
  }
  final List<Marker> markers = [];
  Future<void> _loadPoints() async {
    final snapshot = await firestore.collection('points').get();

    setState(() {
      markers.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        markers.add(
          Marker(
            width: 40,
            height: 40,
            point: LatLng(
              data['latitude'],
              data['longitude'],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
      }
    });
  }

  void _addMarker(LatLng point) {
    setState(() {
      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),
        ),
      );
    });
  }

  Future<void> _showNameDialog(LatLng point) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nom du point"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Exemple : Maison",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              await firestore.collection('points').add({
                'nom': controller.text,
                'latitude': point.latitude,
                'longitude': point.longitude,
              });

              await _loadPoints();

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Point enregistré avec succès !"),
                ),
              );
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carte"),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(48.8566, 2.3522),
          initialZoom: 13,
          onTap: (tapPosition, point) {
            _showNameDialog(point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: "com.example.points_flett_map",
          ),
          MarkerLayer(
            markers: markers,
          ),
        ],
      ),
    );
  }
}

