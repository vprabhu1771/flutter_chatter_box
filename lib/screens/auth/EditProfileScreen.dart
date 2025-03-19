import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    nameController.text = user?.userMetadata?['name'] ?? '';
    phoneController.text = user?.userMetadata?['phone'] ?? '';
    addressController.text = user?.userMetadata?['address'] ?? '';
  }

  Future<void> updateUser() async {
    if (_formKey.currentState!.validate()) {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': nameController.text,
            'phone': phoneController.text,
            'address': addressController.text,
          },
        ),
      );

      // await supabase.from('profiles').update({
      //   'name': nameController.text,
      //   'phone': phoneController.text,
      //   'address': addressController.text,
      // }).eq('id', user!.id);

      Navigator.pop(context, true); // Return true on success
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
                validator: (value) => value!.isEmpty ? "Enter your name" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? "Enter your phone number" : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: addressController,
                decoration: InputDecoration(labelText: "Address"),
                validator: (value) => value!.isEmpty ? "Enter your address" : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: updateUser,
                child: Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}