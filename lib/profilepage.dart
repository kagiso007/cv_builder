import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cv_builder/homepage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.title});

  final String title;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

void _updateUserDetails(
    String fullName, String email, String biography, String password) {
  final user = FirebaseAuth.instance.currentUser;
  final CollectionReference<Map<String, dynamic>> usersRef =
      FirebaseFirestore.instance.collection('users');
  usersRef.doc(user?.uid).set({
    'id': user?.uid,
    'email': email,
    'password': password,
    'displayName': fullName,
    'bio': biography,
  }, SetOptions(merge: true));
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController confirmEmailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = auth.currentUser;

    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      setState(() {
        _imageUrl = userDoc['photoUrl'] ?? '';
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      User? user = auth.currentUser;

      if (user != null) {
        try {
          // Upload image to Firebase Storage
          String filePath = 'profilePictures/${user.uid}.png';
          await _storage.ref(filePath).putFile(file);
          String downloadUrl = await _storage.ref(filePath).getDownloadURL();

          // Update image URL in Firestore
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({'photoUrl': downloadUrl});

          setState(() {
            _imageUrl = downloadUrl;
          });
        } catch (e) {
          print('Error uploading image: $e');
        }
      }
    }
  }

  Future openDialog() => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('please enter your log in details'),
          content: Form(
            key: _formKey2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: confirmEmailController,
                  decoration: const InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.blue,
                      ),
                      hintText: "Enter your email",
                      hintStyle: TextStyle(color: Colors.blue),
                      labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.blue,
                      ),
                      hintText: "Enter your email",
                      labelText: 'password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey2.currentState?.validate() ?? false) {
                  await FirebaseAuth.instance.currentUser?.reload();
                  if (EmailValidator.validate(confirmEmailController.text)) {
                    if (confirmEmailController.text.isNotEmpty) {
                      try {
                        //showLoaderDialog(context);
                        final credential = await FirebaseAuth.instance
                            .signInWithEmailAndPassword(
                                email: confirmEmailController.text,
                                password: confirmPasswordController.text);
                        Navigator.of(context).pop();
                        Route route = MaterialPageRoute(
                            builder: (context) => const HomePage(
                                  title: "Create CV",
                                ));
                        Navigator.push(context, route);
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'user-not-found') {
                          Fluttertoast.showToast(
                              msg: "No user found for that email.",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              textColor: Colors.white,
                              fontSize: 16.0);
                        } else if (e.code == 'wrong-password') {
                          Fluttertoast.showToast(
                              msg: "Wrong password provided for that user.",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                      }
                    } else {
                      Fluttertoast.showToast(
                          msg: "Please enter password",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 2,
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          textColor: Colors.white,
                          fontSize: 16.0);
                    }
                  } else {
                    Fluttertoast.showToast(
                        msg: "Please enter valid email",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        timeInSecForIosWeb: 2,
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        textColor: Colors.white,
                        fontSize: 16.0);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      );

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
          _imageUrl = document['photoUrl'];
        });
      } else {
        setState(() {
          passwordController.text = "password";
          emailController.text = "email";
          usernameController.text = "full name";
          bioController.text = "biography";
          _imageUrl = "https://cdn.pixabay.com/photo/2015/10/05/";
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
        backgroundColor: Colors.blue,
      ),

      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _imageUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_imageUrl),
                      )
                    : const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 50),
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle:
                          const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: _pickAndUploadImage,
                  child: const Text('Change Profile Picture'),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blue,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your full name",
                        border: OutlineInputBorder(),
                        labelText: "full name"),
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
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blue,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.mail,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your email",
                        border: OutlineInputBorder(),
                        labelText: "Email"),
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
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.blue,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your password",
                        border: OutlineInputBorder(),
                        labelText: "password"),
                    validator: (value) {
                      if (value != null && value.isEmpty) {
                        return 'Please enter a valid passoword';
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
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.blue,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.person,
                        color: Colors.blue,
                      ),
                      hintText: "Enter your biography",
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                          textStyle: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        openDialog();
                        _updateUserDetails(
                            usernameController.text,
                            emailController.text,
                            bioController.text,
                            passwordController.text);
                        User? user = auth.currentUser;
                        if (user != null) {
                          //await user?.reauthenticateWithCredential(credential);
                          await user.updatePassword(passwordController.text);
                          //await user?.updateEmail(emailController.text);
                        }

                        //_submitForm();
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
