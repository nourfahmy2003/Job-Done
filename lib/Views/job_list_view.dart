import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../Model/job_entry_model.dart';
import '../Controller/job_entry_service.dart';
import './login.dart';
import './add_job_view.dart';
import './offers_view.dart';

class JobListView extends StatefulWidget {
  const JobListView({super.key});

  @override
  State<JobListView> createState() => _JobListViewState();
}

class _JobListViewState extends State<JobListView> {
  final JobService jobService = JobService();
  String userName = ''; // To store the user's name

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? '';
        });
      }
    }
  }

  Map<String, List<Job>> _groupEntriesByMonth(List<Job> entries) {
    Map<String, List<Job>> groupedEntries = {};
    for (var entry in entries) {
      String monthYear =
          DateFormat('MMMM yyyy').format(entry.jobDateRange.start);
      groupedEntries.putIfAbsent(monthYear, () => []).add(entry);
    }
    return groupedEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          userName.isEmpty ? "My Jobs" : "My Jobs - $userName", // Display name
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.request_page),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OffersView(jobId: 'all')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: jobService.getUserJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Something went wrong: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 72, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No jobs found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a new job',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          final jobs = snapshot.data!;
          jobs.sort(
              (a, b) => b.jobDateRange.start.compareTo(a.jobDateRange.start));
          final grouped = _groupEntriesByMonth(jobs);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: grouped.entries.map((entry) {
              String monthYear = entry.key;
              List<Job> jobs = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      monthYear,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  ...jobs.map((job) {
                    final formattedDate =
                        '${DateFormat('MMM d').format(job.jobDateRange.start)} - ${DateFormat('MMM d').format(job.jobDateRange.end)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                             height: 200,
                             decoration: BoxDecoration(
                               color: Colors.grey[300],
                               borderRadius: const BorderRadius.vertical(
                                 top: Radius.circular(12),
                               ),
                             ),
                             child: job.imageUrls.isNotEmpty
                                 ? CarouselSlider(
                                     options: CarouselOptions(
                                       height: 200,
                                       enableInfiniteScroll: false,
                                       viewportFraction: 1.0,
                                       autoPlay: true,
                                     ),
                                     items: job.imageUrls.map((url) {
                                       return ClipRRect(
                                         borderRadius:
                                             const BorderRadius.vertical(
                                           top: Radius.circular(12),
                                         ),
                                         child: Image.network(
                                           url,
                                           height: 200,
                                           width: double.infinity,
                                           fit: BoxFit.cover,
                                         ),
                                       );
                                     }).toList(),
                                   )
                                 : Center(
                                     child: Icon(
                                       Icons.work_outline,
                                       size: 60,
                                       color: Colors.grey[600],
                                     ),
                                   ),
                           ),
 
                           // Job Details
                           Padding(
                             padding: const EdgeInsets.all(16),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   job.desc,
                                   style: const TextStyle(
                                     fontSize: 16,
                                     color: Colors.black,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 Row(
                                   children: [
                                     Icon(
                                       Icons.calendar_today,
                                       size: 16,
                                       color: Colors.grey[600],
                                     ),
                                     const SizedBox(width: 8),
                                     Text(
                                       formattedDate,
                                       style: TextStyle(
                                         color: Colors.grey[600],
                                       ),
                                     ),
                                     const Spacer(),
                                     Text(
                                       '\$${job.price}',
                                       style: const TextStyle(
                                         fontSize: 18,
                                         color: Colors.black,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 8),
                                 Text(
                                   'Status: ${job.status.toUpperCase()}',
                                   style: TextStyle(
                                     color: job.status == 'pending'
                                         ? Colors.orange
                                         : job.status == 'accepted'
                                             ? Colors.green
                                             : Colors.red,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                                 if (job.status == 'pending')
                                   Padding(
                                     padding: const EdgeInsets.only(top: 12),
                                     child: SizedBox(
                                       width: double.infinity,
                                       child: ElevatedButton(
                                         onPressed: () {
                                           Navigator.push(
                                             context,
                                             MaterialPageRoute(
                                               builder: (_) =>
                                                   OffersView(jobId: job.id!),
                                             ),
                                           );
                                         },
                                         style: ElevatedButton.styleFrom(
                                           backgroundColor: Colors.black,
                                           foregroundColor: Colors.white,
                                           padding: const EdgeInsets.symmetric(
                                               vertical: 12),
                                         ),
                                         child: const Text('View Offers'),
                                       ),
                                     ),
                                   ),
                               ],
                             ),
                           ),
 
                           // Action Buttons
                           Padding(
                             padding: const EdgeInsets.symmetric(
                                 horizontal: 16, vertical: 8),
                             child: Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                 // Edit Button
                                 ElevatedButton.icon(
                                   onPressed: () {
                                     Navigator.push(
                                       context,
                                       MaterialPageRoute(
                                         builder: (context) =>
                                             JobForm(initialData: job),
                                       ),
                                     );
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.blue[800],
                                     foregroundColor: Colors.white,
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 16,
                                       vertical: 8,
                                     ),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                   ),
                                   icon: const Icon(Icons.edit,
                                       size: 18, color: Colors.white),
                                   label: const Text('Edit'),
                                 ),
                                 const SizedBox(width: 8),
                                 // Delete Button
                                 ElevatedButton.icon(
                                   onPressed: () async {
                                     await jobService.deleteJob(job.id!);
                                   },
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.red[900],
                                     foregroundColor: Colors.white,
                                     padding: const EdgeInsets.symmetric(
                                       horizontal: 16,
                                       vertical: 8,
                                     ),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(8),
                                     ),
                                   ),
                                   icon: const Icon(Icons.delete,
                                       size: 18, color: Colors.white),
                                   label: const Text('Delete'),
                                 ),
                               ],
                             ),
                           ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobForm()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
