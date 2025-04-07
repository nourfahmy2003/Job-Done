import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../Controller/job_entry_service.dart';
import '../Model/job_entry_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'dart:typed_data'; 

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

  Future<BitmapDescriptor> _createCustomMarker(Job job) async {
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    final double price = job.price.toDouble();
    
    textPainter.text = TextSpan(
      text: '\$${price.toStringAsFixed(0)}',
      style: const TextStyle(
        fontSize: 35,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
    
    textPainter.layout();
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final Paint circlePaint = Paint()..color = Theme.of(context).primaryColor;
    canvas.drawCircle(const Offset(40, 40), 40, circlePaint);
    
    textPainter.paint(
      canvas,
      Offset(
        40 - textPainter.width / 2,
        40 - textPainter.height / 2,
      ),
    );
    
    final ui.Image image = await pictureRecorder.endRecording().toImage(80, 80);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _acceptJob(Job job) async {
    final String? fixerId = FirebaseAuth.instance.currentUser?.uid;
    if (fixerId == null || job.id == null) return;

    await FirebaseFirestore.instance.collection('offers').add({
      'fixerId': fixerId,
      'jobId': job.id,
      'proposedPrice': job.price,
      'proposedStart': Timestamp.fromDate(job.jobDateRange.start),
      'proposedEnd': Timestamp.fromDate(job.jobDateRange.end),
      'message': 'Accepting job at listed price.',
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Your offer at listed price has been sent.")),
    );
  }

  void _showOfferDialog(BuildContext context, Job job) {
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Make Your Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Your Price"),
            ),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: "Message"),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Submit Offer"),
            onPressed: () async {
              final price = double.tryParse(priceController.text.trim());
              final message = messageController.text.trim();
              final String? fixerId = FirebaseAuth.instance.currentUser?.uid;

              if (price == null || fixerId == null || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill in all fields.")),
                );
                return;
              }

              await FirebaseFirestore.instance.collection('offers').add({
                'fixerId': fixerId,
                'jobId': job.id,
                'proposedPrice': price,
                'message': message,
                'status': 'pending',
                'proposedStart': Timestamp.fromDate(job.jobDateRange.start),
                'proposedEnd': Timestamp.fromDate(job.jobDateRange.end),
                'timestamp': FieldValue.serverTimestamp(),
              });

              Navigator.of(ctx).pop();
              Navigator.pop(context); // Close job details
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Your offer has been submitted.")),
              );
            },
          ),
        ],
      ),
    );
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

      for (var job in nearbyJobs) {
        final customMarker = await _createCustomMarker(job);
        setState(() {
          _markers.add(
            Marker(
              markerId: MarkerId(job.id ?? ''),
              position: LatLng(job.latitude, job.longitude),
              icon: customMarker,
              onTap: () => _showJobDetails(context, job),
            ),
          );
        });
      }
    } catch (e) {
      print("Error loading jobs: $e");
    }
  }

  void _showJobDetails(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar at the top
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Job Description and Price Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              job.desc,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              '\$${job.price}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Category and Status Pills
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              job.category,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: job.status == 'pending'
                                  ? Colors.orange[100]
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              job.status,
                              style: TextStyle(
                                color: job.status == 'pending'
                                    ? Colors.orange[900]
                                    : Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Date and Time Info Cards
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _formatDateRange(job.jobDateRange),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimeRange(job.dailyTimeRange),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Images Section
                      if (job.imageUrls.isNotEmpty) ...[
                        const Text(
                          'Job Images',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: job.imageUrls.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    job.imageUrls[index],
                                    fit: BoxFit.cover,
                                    width: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.broken_image, size: 40),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Accept/Offer Buttons
              if (job.status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptJob(job),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Accept Job as Listed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showOfferDialog(context, job),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Make Your Offer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.toString().split(' ')[0]} to ${range.end.toString().split(' ')[0]}';
  }

  String _formatTimeRange(TimeOfDayRange range) {
    String formatTimeOfDay(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${formatTimeOfDay(range.start)} - ${formatTimeOfDay(range.end)}';
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
