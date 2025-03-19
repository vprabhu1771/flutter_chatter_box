import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../HomeScreen.dart';
import 'LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  final String title;

  const RegisterScreen({super.key, required this.title});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final storage = FlutterSecureStorage(); // Secure storage instance
  final supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _obscureText = true; // To toggle password visibility

  @override
  void initState() {
    super.initState();
    nameController.text = "admin";
    phoneController.text = "1234567890";
    emailController.text = "admin@gmail.com";
    passwordController.text = "admin@123";
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
        data: {
          'name': nameController.text, // Add the name field
          'phone': phoneController.text, // Add the phone field
        },
      );

      Fluttertoast.showToast(msg: "Registration Successful!");
      signIn();
    } catch (error) {
      Fluttertoast.showToast(msg: "Error: ${error.toString()}");
      print("Error: ${error.toString()}");
    }
    setState(() => _isLoading = false);
  }

  Future<void> signIn() async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (response.session != null) {
        await storage.write(key: 'session', value: response.session!.accessToken);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!')),
        );

        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => HomeScreen(title: 'Home')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: nameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                value!.isEmpty ? 'Enter a valid Full Name' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone'),
                validator: (value) =>
                value!.isEmpty ? 'Enter a valid Phone' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                value!.isEmpty ? 'Enter a valid email' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value!.length < 6 ? 'Password must be at least 6 characters' : null,
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _signUp,
                child: Text('Register'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => LoginScreen(title: 'Login')),
                  );
                },
                child: Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}