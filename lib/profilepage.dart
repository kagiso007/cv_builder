import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.title});

  final String title;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

void _getUserDetails() async {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = auth.currentUser;
  String userId = user?.uid ?? '';
  DocumentReference userDocument = firestore.collection('users').doc(userId);

  userDocument.get().then((DocumentSnapshot document) {
    if (document.exists) {
      print('User Data: ${document.data()}');
      print(document['displayName']);
      print(document['bio']);
    } else {
      print('No user data found');
    }
  });
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    User? user = auth.currentUser;
    String userId = user?.uid ?? '';

    DocumentReference userDocument = firestore.collection('users').doc(userId);

    userDocument.get().then((DocumentSnapshot document) {
      if (document.exists) {
        setState(() {
          passwordController.text = document['password'];
          emailController.text = document['email'];
          usernameController.text = document['displayName'];
          bioController.text = document['bio'];
        });
      } else {
        setState(() {
          passwordController.text = "password";
          emailController.text = "email";
          usernameController.text = "full name";
          bioController.text = "biography";
        });
      }
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      String inputValue = usernameController.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(200),
                    child: const Image(
                        image: AssetImage('assets/images/profile_image.jpg')),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "full name"),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Please enter full name';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "Email"),
                    validator: (value) {
                      if (!EmailValidator.validate(emailController.text)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), labelText: "password"),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: bioController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "biography",
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 50.0, horizontal: 10.0),
                    ),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'please enter your biography';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        _getUserDetails();
                        _submitForm();
                      },
                      child: const Text('update profile'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
