import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/offer_model.dart';

class OfferService {
  final CollectionReference _offersCollection =
      FirebaseFirestore.instance.collection('offers');

  Future<List<Offer>> getOffersForJob(String jobId) async {
    try {
      final querySnapshot = await _offersCollection
          .where('jobId', isEqualTo: jobId)
          .get();
      return querySnapshot.docs.map((doc) => Offer.fromMap(doc)).toList();
    } catch (e) {
      print("Error fetching offers: $e");
      return [];
    }
  }

  Future<void> addOffer(Offer offer) async {
    try {
      await _offersCollection.add(offer.toMap());
    } catch (e) {
      print("Error adding offer: $e");
    }
  }

  Future<void> updateOfferStatus(String offerId, String status) async {
    try {
      await _offersCollection.doc(offerId).update({'status': status});
    } catch (e) {
      print("Error updating offer status: $e");
    }
  }
}