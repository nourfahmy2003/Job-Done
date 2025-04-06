import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TimeOfDayRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeOfDayRange({required this.start, required this.end});
}

class Job {
  final String? id;
  final String desc;
  final int price;
  final DateTimeRange jobDateRange;
  final TimeOfDayRange dailyTimeRange;
  final List<String> imageUrls;
  final String category;
  final String status;
  final double latitude;
  final double longitude;
  final String ownerId;
  final String? assignedFixerId;

  Job({
    this.id,
    required this.desc,
    required this.price,
    required this.jobDateRange,
    required this.dailyTimeRange,
    required this.imageUrls,
    required this.category,
    this.status = 'pending',
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.ownerId,
    this.assignedFixerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'desc': desc,
      'price': price,
      'startDate': Timestamp.fromDate(jobDateRange.start),
      'endDate': Timestamp.fromDate(jobDateRange.end),
      'startTime': {
        'hour': dailyTimeRange.start.hour,
        'minute': dailyTimeRange.start.minute
      },
      'endTime': {
        'hour': dailyTimeRange.end.hour,
        'minute': dailyTimeRange.end.minute
      },
      'imageUrls': imageUrls,
      'category': category,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'ownerId': ownerId,
      'assignedFixerId': assignedFixerId,
    };
  }

  static Job fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Job(
      id: doc.id, 
      desc: data['desc'] ?? '',
      price: data['price'] ?? 0,
      jobDateRange: DateTimeRange(
        start: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        end: (data['endDate'] as Timestamp?)?.toDate() ??
            DateTime.now().add(Duration(days: 1)),
      ),
      dailyTimeRange: TimeOfDayRange(
        start: TimeOfDay(
          hour: data['startTime']?['hour'] ?? 0,
          minute: data['startTime']?['minute'] ?? 0,
        ),
        end: TimeOfDay(
          hour: data['endTime']?['hour'] ?? 0,
          minute: data['endTime']?['minute'] ?? 0,
        ),
      ),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'] ?? '',
      status: data['status'] ?? 'pending',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      ownerId:
          data['ownerId'] ?? '', 
      assignedFixerId: data['assignedFixerId'],
    );
  }

  Job copyWith({
    String? id,
    String? desc,
    int? price,
    DateTimeRange? jobDateRange,
    TimeOfDayRange? dailyTimeRange,
    List<String>? imageUrls,
    String? category,
    String? status,
    double? latitude,
    double? longitude,
    String? ownerId,
    String? assignedFixerId,
  }) {
    return Job(
      id: id ?? this.id,
      desc: desc ?? this.desc,
      price: price ?? this.price,
      jobDateRange: jobDateRange ?? this.jobDateRange,
      dailyTimeRange: dailyTimeRange ?? this.dailyTimeRange,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ownerId: ownerId ?? this.ownerId,
      assignedFixerId: assignedFixerId ?? this.assignedFixerId,
    );
  }
}
