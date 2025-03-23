// Updated DiaryListView and DiaryStatisticsView to work with the Job model
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/services.dart';
import '../Model/job_entry_model.dart';
import '../Controller/job_entry_service.dart';
import './login.dart';
import './add_job_view.dart';
// import './diary_statistics_view.dart';

class JobListView extends StatelessWidget {
  const JobListView({super.key});

  Map<String, List<Job>> _groupEntriesByMonth(List<Job> entries) {
    Map<String, List<Job>> groupedEntries = {};
    for (var entry in entries) {
      String monthYear = DateFormat('MMMM yyyy').format(entry.jobDateRange.start);
      groupedEntries.putIfAbsent(monthYear, () => []).add(entry);
    }
    return groupedEntries;
  }

  double _calculateAveragePrice(List<Job> entries) {
    double total = entries.fold(0, (sum, entry) => sum + entry.price);
    return entries.isNotEmpty ? total / entries.length : 0.0;
  }

  Future<void> exportJobsToPdf(List<Job> entries, String title) async {
    final pdf = pw.Document();
    Map<String, Uint8List> loadedImages = {};

    for (var entry in entries) {
      for (var imageUrl in entry.imageUrls) {
        if (!loadedImages.containsKey(imageUrl)) {
          final ByteData imageData = await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
          loadedImages[imageUrl] = imageData.buffer.asUint8List();
        }
      }
    }

    final groupedEntries = _groupEntriesByMonth(entries);

    for (var entry in groupedEntries.entries) {
      String monthYear = entry.key;
      List<Job> monthEntries = entry.value;
      double average = _calculateAveragePrice(monthEntries);

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(monthYear, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.Text('Average Price: \$${average.toStringAsFixed(2)}'),
                pw.SizedBox(height: 10),
                ...monthEntries.map((job) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('From ${DateFormat('MMM d').format(job.jobDateRange.start)} to ${DateFormat('MMM d').format(job.jobDateRange.end)}'),
                      pw.Text('Price: \$${job.price}'),
                      pw.Text(job.desc),
                      if (job.imageUrls.isNotEmpty)
                        pw.Wrap(
                          children: job.imageUrls.map((url) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.all(4),
                              child: pw.Image(pw.MemoryImage(loadedImages[url]!), width: 100, height: 100),
                            );
                          }).toList(),
                        ),
                      pw.Divider(),
                    ],
                  );
                })
              ],
            );
          },
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/$title.pdf");
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final JobService jobService = JobService();
    int _currentIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Jobs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: jobService.getUserJobs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No jobs found.'));
          }

          final jobs = snapshot.data!;
          jobs.sort((a, b) => b.jobDateRange.start.compareTo(a.jobDateRange.start));
          final grouped = _groupEntriesByMonth(jobs);

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: grouped.entries.map((entry) {
              String monthYear = entry.key;
              List<Job> jobs = entry.value;
              double avg = _calculateAveragePrice(jobs);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(monthYear, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Avg Price: \$${avg.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final formattedDate = '${DateFormat('MMM d').format(job.jobDateRange.start)} - ${DateFormat('MMM d').format(job.jobDateRange.end)}';

                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (job.imageUrls.isNotEmpty)
                              CarouselSlider(
                                options: CarouselOptions(
                                  height: 120,
                                  enableInfiniteScroll: false,
                                  viewportFraction: 1.0,
                                  onPageChanged: (index, reason) => _currentIndex = index,
                                ),
                                items: job.imageUrls.map((url) {
                                  return ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: Image.network(url, height: 120, width: double.infinity, fit: BoxFit.cover),
                                  );
                                }).toList(),
                              )
                            else
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(formattedDate, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  Text('Price: \$${job.price}'),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => JobForm(initialData: job)),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await jobService.deleteJob(job.id!);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JobForm())),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () async {
              final jobs = await jobService.getUserJobs().first;
              exportJobsToPdf(jobs, 'Jobs_Export');
            },
            child: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
    );
  }
}