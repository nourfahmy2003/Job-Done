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
  final String status; // Add this field

  Job({
    this.id,
    required this.desc,
    required this.price,
    required this.jobDateRange,
    required this.dailyTimeRange,
    required this.imageUrls,
    required this.category,
    this.status = 'pending', // Default value
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
      'status': status, // Add this line
    };
  }

  static Job fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Job(
      id: doc.id,
      desc: data['desc'],
      price: data['price'],
      jobDateRange: DateTimeRange(
        start: (data['startDate'] as Timestamp).toDate(),
        end: (data['endDate'] as Timestamp).toDate(),
      ),
      dailyTimeRange: TimeOfDayRange(
        start: TimeOfDay(
          hour: data['startTime']['hour'],
          minute: data['startTime']['minute'],
        ),
        end: TimeOfDay(
          hour: data['endTime']['hour'],
          minute: data['endTime']['minute'],
        ),
      ),
      imageUrls: List<String>.from(data['imageUrls']),
      category: data['category'],
      status: data['status'] ?? 'pending', // Add this line
    );
  }

  Job copyWith({
    String? desc,
    int? price,
    DateTimeRange? jobDateRange,
    TimeOfDayRange? dailyTimeRange,
    List<String>? imageUrls,
    String? category,
  }) {
    return Job(
      id: this.id,
      desc: desc ?? this.desc,
      price: price ?? this.price,
      jobDateRange: jobDateRange ?? this.jobDateRange,
      dailyTimeRange: dailyTimeRange ?? this.dailyTimeRange,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
    );
  }
}
