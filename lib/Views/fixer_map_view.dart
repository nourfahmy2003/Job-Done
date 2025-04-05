import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../Controller/job_entry_service.dart';
import '../Model/job_entry_model.dart';

class FixerMapView extends StatefulWidget {
  const FixerMapView({super.key});

  @override
  State<FixerMapView> createState() => _FixerMapViewState();
}

class _FixerMapViewState extends State<FixerMapView> {
  final JobService _jobService = JobService();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _currentLocation = const LatLng(43.651070, -79.347015); // fallback
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _setCurrentLocation();
    await _loadAvailableJobs(_currentLocation);

    // If map is already created, move camera now
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentLocation, zoom: 14),
        ),
      );
    }
  }

  Future<void> _setCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    }

    final position = await Geolocator.getCurrentPosition();
    _currentLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _locationLoaded = true;
      _markers.add(
        Marker(
          markerId: const MarkerId("my_location"),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );
    });
  }

  Future<void> _loadAvailableJobs(LatLng center) async {
    try {
      final snapshot = await _jobService.getAllJobs();
      const double radiusInKm = 25.0;

      final nearbyJobs = snapshot.where((job) {
        if (job.latitude == 0.0 || job.longitude == 0.0) return false;
        final double distance = Geolocator.distanceBetween(
          center.latitude,
          center.longitude,
          job.latitude,
          job.longitude,
        ) / 1000.0;
        return distance <= radiusInKm;
      }).toList();

      setState(() {
        _markers.removeWhere((m) => m.markerId.value != "my_location");
        _markers.addAll(nearbyJobs.map((job) {
          return Marker(
            markerId: MarkerId(job.id ?? ''),
            position: LatLng(job.latitude, job.longitude),
            infoWindow: InfoWindow(
              title: job.desc,
              snippet: '\$${job.price} | ${job.category}',
            ),
          );
        }));
      });
    } catch (e) {
      print("Error loading jobs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jobs Near Me")),
      body: !_locationLoaded
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 12,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;

          // Move camera once location is loaded
          if (_locationLoaded) {
            controller.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: _currentLocation, zoom: 14),
              ),
            );
          }
        },
        onCameraIdle: () async {
          final bounds = await _mapController!.getVisibleRegion();
          final center = LatLng(
            (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
            (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
          );
          _loadAvailableJobs(center);
        },
      ),
    );
  }
}
