import 'package:flutter/material.dart';
import 'package:cv_builder/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SignUP extends StatefulWidget {
  const SignUP({super.key, required this.title});

  final String title;

  @override
  State<SignUP> createState() => _SignUPState();
}

class _SignUPState extends State<SignUP> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Email"),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Password"),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value != null && value.isEmpty) {
                      return 'Please enter a valid password';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Confirm Password"),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'password do not match';
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
                      if (passwordController.text ==
                              confirmPasswordController.text &&
                          EmailValidator.validate(emailController.text)) {
                        try {
                          final credential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text,
                          );
                          await user?.sendEmailVerification();
                          Fluttertoast.showToast(
                              msg: "account created succefully",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              textColor: Colors.white,
                              fontSize: 16.0);
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const Login(title: "CV BUILDER")),
                          );
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'weak-password') {
                            Fluttertoast.showToast(
                                msg: "The password provided is too weak.",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 2,
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0),
                                textColor: Colors.white,
                                fontSize: 16.0);
                          } else if (e.code == 'email-already-in-use') {
                            Fluttertoast.showToast(
                                msg:
                                    "An account already exists for that email.",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                timeInSecForIosWeb: 2,
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0),
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }
                        } catch (e) {
                          print(e);
                        }
                      } else {
                        Fluttertoast.showToast(
                            msg: "passwords do not match or email is not valid",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 2,
                            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                            textColor: Colors.white,
                            fontSize: 16.0);
                      }
                    },
                    child: Text('sign up'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
