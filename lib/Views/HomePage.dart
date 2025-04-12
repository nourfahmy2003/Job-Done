import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Model/job_entry_model.dart';
import './add_job_view.dart';
import './fixer_map_view.dart';
import '../Controller/job_entry_service.dart';
import './job_detail_view.dart';
import './chat_list_page.dart';
import './MyAccountPage.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final JobService _jobService = JobService();
  final user = FirebaseAuth.instance.currentUser;
  String selectedCategory = 'All';
  String searchQuery = '';
  Set<String> favorites = {};
  Set<String> history = {};

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.list, 'color': Colors.grey},
    {'name': 'Plumbing', 'icon': Icons.plumbing, 'color': Colors.blue},
    {'name': 'Electrical', 'icon': Icons.electrical_services, 'color': Colors.amber},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.lightBlue},
    {'name': 'Painting', 'icon': Icons.format_paint, 'color': Colors.deepPurple},
    {'name': 'Gardening', 'icon': Icons.nature, 'color': Colors.green},
    {'name': 'Other', 'icon': Icons.miscellaneous_services, 'color': Colors.grey},
  ];

  void toggleFavorite(String jobId) {
    setState(() {
      if (favorites.contains(jobId)) {
        favorites.remove(jobId);
      } else {
        favorites.add(jobId);
      }
    });
  }

  void addToHistory(String jobId) {
    setState(() {
      history.add(jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, ${user?.displayName ?? 'there'}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('Explore job listings'),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'account') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyAccountPage()),
                      );
                    } else if (value == 'signout') {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'account',
                      child: Text('My Account'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'signout',
                      child: Text('Sign Out'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: const InputDecoration(
                      hintText: 'Search jobs...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16),
              children: _categories.map((cat) {
                final isSelected = selectedCategory == cat['name'];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat['name']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'], color: isSelected ? Colors.white : Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/home_banner.jpg', 
                fit: BoxFit.cover,
                width: double.infinity,
                height: 160,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Popular Jobs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("View all", style: TextStyle(color: Colors.blue)),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collectionGroup('job').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jobs = snapshot.data!.docs.map((doc) {
                  final job = Job.fromMap(doc);
                  return job.copyWith(id: doc.id);
                }).where((job) =>
                  (selectedCategory == 'All' || job.category == selectedCategory) &&
                  (searchQuery.isEmpty || job.title.toLowerCase().contains(searchQuery.toLowerCase()))
                ).toList();

                if (jobs.isEmpty) {
                  return const Center(child: Text('No jobs found'));
                }

                return SizedBox(
                  height: 280,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final isOwner = job.ownerId == user?.uid;
                      final isFavorite = favorites.contains(job.id);

                      return GestureDetector(
                        onTap: () {
                            addToHistory(job.id!);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailView(
                                  job: job,
                                  isFavorite: favorites.contains(job.id),
                                  onFavoriteToggle: () {
                                    toggleFavorite(job.id!);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            );
                          },

                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  job.imageUrls.isNotEmpty ? job.imageUrls.first : '',
                                  height: 280,
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => toggleFavorite(job.id!),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.8),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        job.category,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "\$${(job.price is int) ? job.price : (job.price as num).toStringAsFixed(2)}",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JobForm()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Post a Job',
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FixerMapView()),
            );
          } else if (index == 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
          } else if (index == 3) {
          }
           
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }

  Widget _topButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.black),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _showListDialog(String title, Set<String> jobIds) {
    return AlertDialog(
      title: Text(title),
      content: jobIds.isEmpty
          ? const Text("No jobs found")
          : SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: jobIds.map((id) => ListTile(title: Text('Job ID: $id'))).toList(),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
