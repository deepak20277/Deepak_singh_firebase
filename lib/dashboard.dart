import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  const DashboardPage({super.key, required this.username});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  // Sample reels images (unsplash)
  final List<String> reelImages = List.generate(
      15,
          (index) =>
      'https://source.unsplash.com/collection/190727/400x400?sig=$index');

  // For Search users page:
  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(reelImages: reelImages),
      SearchPage(
        allUsers: filteredUsers,
        filteredUsers: filteredUsers,
        searchController: searchController,
        onSearchChanged: _onSearchChanged,
      ),
      ProfilePage(username: widget.username, onLogout: _logout),
    ];
    _loadAllUsers();
    searchController.addListener(() {
      _onSearchChanged(searchController.text.trim());
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('username') // make sure your users collection has 'username' field
          .get();

      setState(() {
        allUsers = snapshot.docs
            .map((e) => {
          'username': e.data()['username'] ?? e.id,
          'email': e.data()['email'] ?? '',
        })
            .toList();
        filteredUsers = List.from(allUsers);
      });
    } catch (e) {
      // Handle errors, maybe log or show toast
      setState(() {
        allUsers = [];
        filteredUsers = [];
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers);
      } else {
        filteredUsers = allUsers
            .where((user) =>
            user['username']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        searchController.clear();
        _loadAllUsers();
      }
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<String> reelImages;
  const HomePage({super.key, required this.reelImages});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Reels',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: reelImages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => CircleAvatar(
              radius: 46,
              backgroundImage: NetworkImage(reelImages[index]),
              backgroundColor: Colors.grey[300],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '15 Posts',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class SearchPage extends StatelessWidget {
  final List<Map<String, dynamic>> allUsers;
  final List<Map<String, dynamic>> filteredUsers;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const SearchPage({
    super.key,
    required this.allUsers,
    required this.filteredUsers,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search username',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white60),
            prefixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: filteredUsers.isEmpty
          ? const Center(child: Text('No users found'))
          : ListView.separated(
        itemCount: filteredUsers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          return ListTile(
            title: Text(user['username']),
            subtitle: Text(user['email']),
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String username;
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.username,
    required this.onLogout,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int followerCount = 0;
  int followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadFollowData();
  }

  Future<void> _loadFollowData() async {
    try {
      final followersSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.username)
          .collection('followers')
          .get();
      final followingSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.username)
          .collection('following')
          .get();

      setState(() {
        followerCount = followersSnap.size;
        followingCount = followingSnap.size;
      });
    } catch (e) {
      setState(() {
        followerCount = 0;
        followingCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                widget.username.isNotEmpty
                    ? widget.username[0].toUpperCase()
                    : '?',
                style:
                const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.username,
              style:
              const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCountColumn('Followers', followerCount),
                _buildCountColumn('Following', followingCount),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountColumn(String label, int count) {
    return Column(
      children: [
        Text(
          '$count',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }
}