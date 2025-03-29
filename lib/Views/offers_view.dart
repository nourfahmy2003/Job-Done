import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/offer_model.dart';
import '../Controller/offer_service.dart';

class OffersView extends StatefulWidget {
  final String jobId;
  const OffersView({super.key, required this.jobId});

  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  final OfferService _offerService = OfferService();
  late Future<List<Offer>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = _offerService.getOffersForJob(widget.jobId);
  }

  Future<void> _updateOfferStatus(String offerId, String status) async {
    await _offerService.updateOfferStatus(offerId, status);
    setState(() {
      _offersFuture = _offerService.getOffersForJob(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Job Offers',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Offer>>(
          future: _offersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.request_page, size: 72, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No offers yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            final offers = snapshot.data!;
            return ListView.separated(
              itemCount: offers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offer #${index + 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Price: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '\$${offer.proposedPrice}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Dates: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '${DateFormat('MMM d').format(offer.proposedStart)} - ${DateFormat('MMM d').format(offer.proposedEnd)}',
                          ),
                        ],
                      ),
                      if (offer.message != null) ...[
                        const SizedBox(height: 8),
                        const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(offer.message!),
                      ],
                      const SizedBox(height: 12),
                      if (offer.status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateOfferStatus(offer.id!, 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  side: const BorderSide(color: Colors.black),
                                ),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateOfferStatus(offer.id!, 'accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Accept'),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Status: ${offer.status.toUpperCase()}',
                          style: TextStyle(
                            color: offer.status == 'accepted' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}