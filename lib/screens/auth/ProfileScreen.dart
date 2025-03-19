import 'package:flutter/material.dart';

import '../../widgets/CustomDrawer.dart';
import '../HomeScreen.dart';
import 'EditProfilePicScreen.dart';
import 'EditProfileScreen.dart';

class ProfileScreen extends StatefulWidget {
  final String title;

  const ProfileScreen({super.key, required this.title});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  var user = supabase.auth.currentUser;

  Future<void> refreshUserData() async {
    await supabase.auth.refreshSession();
    setState(() {
      user = supabase.auth.currentUser; // Update user state
    });
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
    await storage.delete(key: 'session');

    // Navigate to login screen and remove all previous routes
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // builder: (context) => LoginScreen(title: 'Login'),
        builder: (context) => HomeScreen(title: 'Home'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Image View
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                          user?.userMetadata?['image_path'] ?? 'https://gravatar.com/avatar/${user!.email}'),
                      backgroundColor: Colors.grey[200],
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {

                          print(user?.userMetadata?['image_path']);

                          bool? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePicScreen(),
                            ),
                          );

                          if (result == true) {
                            // Refresh data after edit
                            // Refresh UI
                            await refreshUserData();
                          }

                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Profile Details List
              ListTile(
                leading: Icon(Icons.person),
                title: Text(user?.userMetadata?['name']), // Replace with dynamic user name
                trailing: Icon(Icons.edit),
                onTap: () async {
                  // Handle the edit profile action
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(),
                    ),
                  );

                  if (result == true) {
                    await refreshUserData(); // Refresh data after edit
                  }
                },
              ),
              const Divider(),

              ListTile(
                leading: Icon(Icons.email),
                title: Text(user!.email ?? ""), // Replace with dynamic user name
                // trailing: Icon(Icons.edit),
                onTap: () {
                  // Handle the edit profile action
                },
              ),
              const Divider(),

              ListTile(
                leading: Icon(Icons.phone),
                title: Text(user?.userMetadata?['phone']), // Replace with dynamic phone number
                onTap: () {
                  // Handle phone number action
                },
              ),
              const Divider(),

              ListTile(
                leading: Icon(Icons.location_on),
                title: Text('New York, USA'), // Replace with dynamic address
                onTap: () {
                  // Handle address action
                },
              ),
              const Divider(),

              // Logout Button (Red color)
              TextButton(
                onPressed: () {

                  signOut();

                  // Handle logout action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out')),
                  );

                },
                child: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}