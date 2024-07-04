import 'package:cv_builder/homepage.dart';
import 'package:flutter/material.dart';
import 'package:cv_builder/signup.dart';
import 'package:cv_builder/forgotpassword.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:animate_do/animate_do.dart';

class Login extends StatefulWidget {
  const Login({super.key, required this.title});

  final String title;

  @override
  State<Login> createState() => _LoginState();
}

showLoaderDialog(BuildContext context) {
  AlertDialog alert = AlertDialog(
    content: Row(
      children: [
        const CircularProgressIndicator(),
        Container(
            margin: const EdgeInsets.only(left: 7),
            child: const Text("Loading...")),
      ],
    ),
  );
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class _LoginState extends State<Login> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        top: -40,
                        height: 400,
                        width: width,
                        child: FadeInUp(
                            duration: const Duration(seconds: 1),
                            child: Container(
                              decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage(
                                          'assets/images/background.png'),
                                      fit: BoxFit.fill)),
                            )),
                      ),
                      Positioned(
                        height: 400,
                        width: width + 20,
                        child: FadeInUp(
                            duration: const Duration(milliseconds: 1000),
                            child: Container(
                              decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage(
                                          'assets/images/background-2.png'),
                                      fit: BoxFit.fill)),
                            )),
                      )
                    ],
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
                        hintText: "Enter your Email",
                        hintStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(),
                        labelText: "Email"),
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
                        hintStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(),
                        labelText: "Password"),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
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
                        await FirebaseAuth.instance.currentUser?.reload();
                        if (EmailValidator.validate(emailController.text)) {
                          if (passwordController.text.isNotEmpty) {
                            try {
                              //showLoaderDialog(context);
                              final credential = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: emailController.text,
                                      password: passwordController.text);
                              //Navigator.pop(context);
                              if (FirebaseAuth
                                  .instance.currentUser!.emailVerified) {
                                Route route = MaterialPageRoute(
                                    builder: (context) => const HomePage(
                                          title: "Create CV",
                                        ));
                                Navigator.push(context, route);
                              } else {
                                Fluttertoast.showToast(
                                    msg: "email is not registered or verified",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 2,
                                    backgroundColor:
                                        const Color.fromARGB(255, 0, 0, 0),
                                    textColor: Colors.white,
                                    fontSize: 16.0);
                              }
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
                                    msg:
                                        "Wrong password provided for that user.",
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
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0),
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }
                        } else {
                          Fluttertoast.showToast(
                              msg: "Please enter valid email",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                      },
                      child: const SizedBox(
                        child: Text("LOGIN"),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Route route = MaterialPageRoute(
                        builder: (context) => const SignUP(
                              title: "signup",
                            ));
                    Navigator.push(context, route);
                  },
                  child: const SizedBox(child: Text("signup")),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(
                          color: Colors.white10,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Route route = MaterialPageRoute(
                        builder: (context) => const resetPassword(
                              title: "reset password",
                            ));
                    Navigator.push(context, route);
                  },
                  child: const SizedBox(child: Text("forgot password?")),
                ),
              ],
            ),
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
