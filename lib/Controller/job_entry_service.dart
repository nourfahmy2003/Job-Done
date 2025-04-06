import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Model/job_entry_model.dart'; 
import 'package:flutter/material.dart';

class JobService {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference jobCollection;

  JobService()
      : jobCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('job') {
    _ensureUserDocumentExists();
  }

  Future<void> _ensureUserDocumentExists() async {
    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid);

    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      await userDocRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'uid': FirebaseAuth.instance.currentUser!.uid,
      });
    }
  }

  /// Check if any job overlaps with a new job's date range
  Future<bool> isDateRangeUnique(DateTimeRange newRange, {String? excludeId}) async {
    final querySnapshot = await jobCollection.get();

    for (var doc in querySnapshot.docs) {
      final existingJob = Job.fromMap(doc);
      if (excludeId != null && existingJob.id == excludeId) continue;

      final existingRange = existingJob.jobDateRange;

      // Check for overlap
      final bool overlaps = newRange.start.isBefore(existingRange.end) &&
                            newRange.end.isAfter(existingRange.start);
      if (overlaps) return false;
    }
    return true;
  }

  Future<DocumentReference<Object?>> addJob(Job job) async {
   
    return await jobCollection.add(job.toMap());
  }

  Future<void> updateJob(Job job) async {
    
    return await jobCollection.doc(job.id).update(job.toMap());
  }

  Future<void> deleteJob(String id) async {
    return await jobCollection.doc(id).delete();
  }

  Stream<List<Job>> getUserJobs() {
    return jobCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Job.fromMap(doc)).toList();
    });
  }
  Future<List<Job>> getAllJobs() async {
  final querySnapshot = await FirebaseFirestore.instance
      .collectionGroup('job') // collects 'job' subcollections across all users
      .get();

  return querySnapshot.docs.map((doc) => Job.fromMap(doc)).toList();
}

}
