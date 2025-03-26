// Updated version of your JobForm to work with the new Job model and JobService
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Model/job_entry_model.dart';
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
  List<File> _selectedImages = [];
  List<String> _existingImages = [];

  String? _selectedCategory;
  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Painting',
    'Gardening',
    'Other',
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
    }
  }

  void _closeForm() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickJobDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _jobDateRange = picked;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? (_startTime ?? TimeOfDay.now()) : (_endTime ?? TimeOfDay.now()),
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
      if (_selectedImages.length + _existingImages.length + pickedFiles.length > 4) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can only add up to 4 images!")),
        );
        return;
      }
      setState(() {
        _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
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

  Future<void> _saveJob() async {
    if (!_formKey.currentState!.validate() ||
        _jobDateRange == null ||
        _startTime == null ||
        _endTime == null ||
        _selectedCategory == null) {
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
    );

    if (_selectedImages.isNotEmpty) {
      final jobId = job.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final uploadedUrls = await StorageService().uploadJobImages(_selectedImages, jobId);
      job.imageUrls.addAll(uploadedUrls);
    }

    if (widget.initialData == null) {
      await jobService.addJob(job);
    } else {
      await jobService.updateJob(job);
    }

    _closeForm();
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _selectedImages.length + _existingImages.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'Add Job' : 'Edit Job'),
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
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 12.0),

              // Category dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Job Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 12.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_jobDateRange != null
                      ? 'From: ${_jobDateRange!.start.toLocal().toString().split(' ')[0]}\nTo: ${_jobDateRange!.end.toLocal().toString().split(' ')[0]}'
                      : 'Pick job date range'),
                  TextButton(
                    onPressed: _pickJobDateRange,
                    child: const Text('Select'),
                  )
                ],
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text(_startTime != null ? _startTime!.format(context) : 'Start Time'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text(_endTime != null ? _endTime!.format(context) : 'End Time'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text('Price: \$${_price.toStringAsFixed(2)}'),
              Slider(
                value: _price,
                min: 0,
                max: 500,
                divisions: 100,
                label: _price.toStringAsFixed(0),
                onChanged: (value) => setState(() => _price = value),
              ),
              const SizedBox(height: 16.0),
              SizedBox(
                height: 150,
                child: totalImages > 0
                    ? ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImages.asMap().entries.map((entry) {
                      int index = entry.key;
                      String imageUrl = entry.value;
                      return _buildImageWithDelete(imageUrl, index, isExisting: true);
                    }),
                    ..._selectedImages.asMap().entries.map((entry) {
                      int index = entry.key;
                      File imageFile = entry.value;
                      return _buildImageWithDelete(imageFile, index, isExisting: false);
                    }),
                  ],
                )
                    : Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.camera_alt, size: 40)),
                ),
              ),
              const SizedBox(height: 8.0),
              ElevatedButton.icon(
                onPressed: totalImages < 4 ? _pickImages : null,
                icon: const Icon(Icons.add_a_photo),
                label: Text(totalImages < 4 ? "Add Images (${totalImages}/4)" : "Max Images Reached"),
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _closeForm,
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _saveJob,
                    child: Text(widget.initialData == null ? 'Submit' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWithDelete(dynamic image, int index, {required bool isExisting}) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: isExisting
              ? Image.network(image, height: 150, fit: BoxFit.cover)
              : Image.file(image, height: 150, fit: BoxFit.cover),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteImage(index, isExisting: isExisting),
          ),
        ),
      ],
    );
  }
}
