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
  final DateTimeRange jobDateRange;     // The overall date range the job should happen in
  final TimeOfDayRange dailyTimeRange;  // The time range user is available *each day*
  final List<String> imageUrls;

  Job({
    this.id,
    required this.desc,
    required this.price,
    required this.jobDateRange,
    required this.dailyTimeRange,
    required this.imageUrls,
  });

  Map<String, dynamic> toMap() {
  return {
    'desc': desc,
    'price': price,
    'jobDateRange': {
      'start': Timestamp.fromDate(jobDateRange.start),
      'end': Timestamp.fromDate(jobDateRange.end),
    },
    'dailyTimeRange': {
      'startHour': dailyTimeRange.start.hour,
      'startMinute': dailyTimeRange.start.minute,
      'endHour': dailyTimeRange.end.hour,
      'endMinute': dailyTimeRange.end.minute,
    },
    'imageUrls': imageUrls,
    'assignedFixerId': null, 
  };
}


  Job copyWith({
    String? desc,
    int? price,
    DateTimeRange? jobDateRange,
    TimeOfDayRange? dailyTimeRange,
    List<String>? imageUrls,
  }) {
    return Job(
      id: this.id,
      desc: desc ?? this.desc,
      price: price ?? this.price,
      jobDateRange: jobDateRange ?? this.jobDateRange,
      dailyTimeRange: dailyTimeRange ?? this.dailyTimeRange,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }

  static Job fromMap(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;

    final dateRangeMap = map['jobDateRange'] as Map<String, dynamic>;
    final timeRangeMap = map['dailyTimeRange'] as Map<String, dynamic>;

    return Job(
      id: doc.id,
      desc: map['desc'] ?? '',
      price: map['price'] ?? 0,
      jobDateRange: DateTimeRange(
        start: (dateRangeMap['start'] as Timestamp).toDate(),
        end: (dateRangeMap['end'] as Timestamp).toDate(),
      ),
      dailyTimeRange: TimeOfDayRange(
        start: TimeOfDay(
          hour: timeRangeMap['startHour'],
          minute: timeRangeMap['startMinute'],
        ),
        end: TimeOfDay(
          hour: timeRangeMap['endHour'],
          minute: timeRangeMap['endMinute'],
        ),
      ),
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.map((item) => item.toString()).toList() ?? [],
    );
  }
}
