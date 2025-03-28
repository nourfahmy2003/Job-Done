import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../Model/job_entry_model.dart';
import '../Controller/job_entry_service.dart';
import './login.dart';
import './add_job_view.dart';

class JobListView extends StatelessWidget {
  const JobListView({super.key});

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
    final JobService jobService = JobService();

    return Scaffold(
      backgroundColor: Colors.white, // Black background
      appBar: AppBar(
        title: const Text(
          "My Jobs",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ...jobs.map((job) {
                    final formattedDate =
                        '${DateFormat('MMM d').format(job.jobDateRange.start)} - ${DateFormat('MMM d').format(job.jobDateRange.end)}';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Image Carousel
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '\$${job.price}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
