import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Offer {
  final String? id;
  final String jobId;
  final String fixerId;
  final int proposedPrice;
  final DateTime proposedStart;
  final DateTime proposedEnd;
  final String status; 
  final String? message;

  Offer({
    this.id,
    required this.jobId,
    required this.fixerId,
    required this.proposedPrice,
    required this.proposedStart,
    required this.proposedEnd,
    required this.status,
    this.message,
  });

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'fixerId': fixerId,
      'proposedPrice': proposedPrice,
      'proposedStart': Timestamp.fromDate(proposedStart),
      'proposedEnd': Timestamp.fromDate(proposedEnd),
      'status': status,
      'message': message,
    };
  }

  static Offer fromMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Offer(
      id: doc.id,
      jobId: data['jobId'],
      fixerId: data['fixerId'],
      proposedPrice: data['proposedPrice'],
      proposedStart: (data['proposedStart'] as Timestamp).toDate(),
      proposedEnd: (data['proposedEnd'] as Timestamp).toDate(),
      status: data['status'],
      message: data['message'],
    );
  }
}
