import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePicScreen extends StatefulWidget {
  @override
  _EditProfilePicScreenState createState() => _EditProfilePicScreenState();
}

class _EditProfilePicScreenState extends State<EditProfilePicScreen> {
  final supabase = Supabase.instance.client;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final fileName = '${user.id}.jpg';
      final filePath = 'profile_pictures/$fileName';

      // Fetch current user metadata to get previous image path
      final userMetadata = user.userMetadata;
      final previousImageUrl = userMetadata?['image_path'];

      // Delete the previous image if it exists
      if (previousImageUrl != null) {
        final oldFilePath = previousImageUrl.split('/profile_pictures/').last;
        await supabase.storage.from('assets').remove(['profile_pictures/$oldFilePath']);
      }

      // Upload new image with overwrite option
      await supabase.storage.from('assets').upload(
        filePath,
        _image!,
        fileOptions: const FileOptions(upsert: true), // Enables overwrite
      );

      // Get the new public URL
      // final imageUrl = supabase.storage.from('assets').getPublicUrl(filePath);
      final imageUrl = '${supabase.storage.from('assets').getPublicUrl(filePath)}?t=${DateTime.now().millisecondsSinceEpoch}';


      print(imageUrl);

      // Update user metadata with new image path
      final response = await supabase.auth.updateUser(
        UserAttributes(data: {'image_path': imageUrl}),
      );

      print(response.toString());

      Navigator.pop(context, true); // Return success
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Profile Picture')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: _image != null
                ? CircleAvatar(
              radius: 60,
              backgroundImage: FileImage(_image!),
            )
                : CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person, size: 40),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _uploadImage,
            child: Text('Upload Image'),
          ),
        ],
      ),
    );
  }
}