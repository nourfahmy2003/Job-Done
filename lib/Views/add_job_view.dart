import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../Model/job_entry_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Controller/job_entry_service.dart';
import '../Controller/storage_service.dart';

class JobForm extends StatefulWidget {
  final Job? initialData;
  const JobForm({super.key, this.initialData});

  @override
  _JobFormState createState() => _JobFormState();
}

class _JobFormState extends State<JobForm> {
  final _formKey = GlobalKey<FormState>();
  final JobService jobService = JobService();
  final TextEditingController _descriptionController = TextEditingController();
  double _price = 0.0;

  DateTimeRange? _jobDateRange;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<String> _existingImages = [];

  String? _selectedCategory;
  double _latitude = 0.0;
  double _longitude = 0.0;
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Plumbing',
      'icon': Icons.plumbing,
      'color': Colors.blue,
    },
    {
      'name': 'Electrical',
      'icon': Icons.electrical_services,
      'color': Colors.amber,
    },
    {
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.lightBlue,
    },
    {
      'name': 'Painting',
      'icon': Icons.format_paint,
      'color': Colors.deepPurple,
    },
    {
      'name': 'Gardening',
      'icon': Icons.nature,
      'color': Colors.green,
    },
    {
      'name': 'Other',
      'icon': Icons.miscellaneous_services,
      'color': Colors.grey,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _descriptionController.text = widget.initialData!.desc;
      _price = widget.initialData!.price.toDouble();
      _jobDateRange = widget.initialData!.jobDateRange;
      _startTime = widget.initialData!.dailyTimeRange.start;
      _endTime = widget.initialData!.dailyTimeRange.end;
      _existingImages = List.from(widget.initialData!.imageUrls);
      _selectedCategory = widget.initialData!.category;
      _latitude = widget.initialData!.latitude;
      _longitude = widget.initialData!.longitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _selectedImages.length + _existingImages.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.initialData == null ? 'Add Job' : 'Edit Job',
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                maxLength: 120,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Job Description',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.description, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: const Text("Use Current Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_latitude != 0.0 && _longitude != 0.0)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Lat: ${_latitude.toStringAsFixed(5)}, Lng: ${_longitude.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Job Category',
                  labelStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.category, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categories
                    .map<DropdownMenuItem<String>>(
                        (category) => DropdownMenuItem<String>(
                              value: category['name'],
                              child: Row(
                                children: [
                                  Icon(
                                    category['icon'],
                                    color: category['color'],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    category['name'],
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ))
                    .toList(),
                onChanged: (String? value) =>
                    setState(() => _selectedCategory = value),
                validator: (String? value) =>
                    value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text(
                          _jobDateRange != null
                              ? '${DateFormat('MMM d').format(_jobDateRange!.start)} - ${DateFormat('MMM d').format(_jobDateRange!.end)}'
                              : 'Select date range',
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _pickJobDateRange,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Select Dates'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      time: _startTime,
                      label: 'Start Time',
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      time: _endTime,
                      label: 'End Time',
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_money, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Price',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${_price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: _price,
                    min: 0,
                    max: 500,
                    divisions: 100,
                    label: _price.toStringAsFixed(0),
                    activeColor: Colors.black,
                    inactiveColor: Colors.grey[300],
                    onChanged: (value) => setState(() => _price = value),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              const Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Images',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                '(${totalImages}/4)',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8.0),
              SizedBox(
                height: 150,
                child: totalImages > 0
                    ? ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._existingImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            String imageUrl = entry.value;
                            return _buildImageWithDelete(imageUrl, index,
                                isExisting: true);
                          }),
                          ..._selectedImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            XFile imageFile = entry.value;
                            return _buildImageWithDelete(imageFile, index,
                                isExisting: false);
                          }),
                        ],
                      )
                    : Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add images',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton.icon(
                onPressed: totalImages < 4 ? _pickImages : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: totalImages < 4 ? Colors.black : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                label:
                    Text(totalImages < 4 ? "Add Images" : "Max Images Reached"),
              ),
              const SizedBox(height: 32.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _closeForm,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        Text(widget.initialData == null ? 'Submit' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required TimeOfDay? time,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  label == 'Start Time' ? Icons.alarm_on : Icons.alarm_off,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time != null ? time.format(context) : 'Not set',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithDelete(dynamic image, int index,
      {required bool isExisting}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isExisting
                ? Image.network(
                    image,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey,
                      child: const Icon(Icons.error),
                    ),
                  )
                : FutureBuilder<Uint8List>(
                    future: (image as XFile).readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        height: 150,
                        width: 150,
                        color: Colors.grey,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _deleteImage(index, isExisting: isExisting),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _pickJobDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _jobDateRange = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      if (_selectedImages.length + _existingImages.length + pickedFiles.length >
          4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can only add up to 4 images!")),
        );
        return;
      }
      setState(() {
        _selectedImages.addAll(pickedFiles);
      });
    }
  }

  void _deleteImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImages.removeAt(index);
      } else {
        _selectedImages.removeAt(index);
      }
    });
  }

  void _closeForm() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate() ||
        _jobDateRange == null ||
        _startTime == null ||
        _endTime == null ||
        _selectedCategory == null ||
        _latitude == 0.0 ||
        _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    _formKey.currentState!.save();

    final timeRange = TimeOfDayRange(start: _startTime!, end: _endTime!);

    final job = Job(
      id: widget.initialData?.id,
      desc: _descriptionController.text,
      price: _price.toInt(),
      jobDateRange: _jobDateRange!,
      dailyTimeRange: timeRange,
      imageUrls: _existingImages,
      category: _selectedCategory!,
      latitude: _latitude,
      longitude: _longitude,
      ownerId: FirebaseAuth.instance.currentUser!.uid, // ✅ Add this line
    );

    if (_selectedImages.isNotEmpty) {
      final jobId = job.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final uploadedUrls =
          await StorageService().uploadJobImages(_selectedImages, jobId);
      job.imageUrls.addAll(uploadedUrls);
    }

    if (widget.initialData == null) {
      await jobService.addJob(job);
    } else {
      await jobService.updateJob(job);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
