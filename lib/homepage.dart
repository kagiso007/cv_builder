import 'package:flutter/material.dart';
import 'package:cv_builder/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cv_builder/profilepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

/*class PredictiveTextProvider with ChangeNotifier {
  final PredictiveTextService _service = PredictiveTextService();
  String _predictedText = '';

  String get predictedText => _predictedText;

  void fetchPredictiveText(String inputText) async {
    _predictedText = await _service.getPredictiveText(inputText);
    notifyListeners();
  }
}*/

void _updateUserDetails(
    String fullName,
    String email,
    String biography,
    String achievements,
    String experience,
    String idNumber,
    String highSchool,
    String tertiary) {
  final user = FirebaseAuth.instance.currentUser;
  final CollectionReference<Map<String, dynamic>> usersRef =
      FirebaseFirestore.instance.collection('users');
  usersRef.doc(user?.uid).set({
    'id': user?.uid,
    'email': email,
    'id_number': idNumber,
    'high_school': highSchool,
    'experience': experience,
    'achievements': achievements,
    'tertiary': tertiary,
    'displayName': fullName,
    'bio': biography,
  }, SetOptions(merge: true));
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController usernameController = TextEditingController();
  TextEditingController IDController = TextEditingController();
  TextEditingController highSchoolPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController tertiaryController = TextEditingController();
  TextEditingController experienceController = TextEditingController();
  TextEditingController biographyController = TextEditingController();
  TextEditingController achievementController = TextEditingController();
  final String password = "";
  bool isLoading = false;
  final String photoURL = "";
  String message = '';

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    List<Map<String, dynamic>> users = [];
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();

    for (var doc in snapshot.docs) {
      users.add(doc.data() as Map<String, dynamic>);
    }

    return users;
  }

  void _generatePdf() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> users = await fetchUsers();
      await generatePdf(users);
      setState(() {
        message = 'PDF generated successfully!';
      });
    } catch (e) {
      setState(() {
        message = 'Error generating PDF: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserData();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  final CollectionReference collectionReference =
      FirebaseFirestore.instance.collection('users');

  Future<List<Map<String, dynamic>>> fetchData() async {
    QuerySnapshot querySnapshot = await collectionReference.get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> generatePdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    for (var item in data) {
      // Extract specific attributes from Firestore document
      String name = item['displayName'];
      String email = item['email'];
      String bio = item['bio'];
      String idNumber = item['id_number'];
      String highSchool = item['high_school'];
      String tertiary = item['tertiary'];
      String achievements = item['achievements'];
      final imageUrl = item['photoUrl'];
      final response = await http.get(Uri.parse(imageUrl));
      final image = pw.MemoryImage(response.bodyBytes);

      // Add content to PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            children: [
              pw.Text(
                'Curriculum Vitae',
                style:
                    pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(bio),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(width: 50),
                  pw.Container(
                    width: 150,
                    height: 150,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(
                        image: image,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                data: [
                  ['Name ', name],
                  ['Email ', email],
                  ['identity number', idNumber],
                  ['high_school ', highSchool],
                  ['higher education ', tertiary],
                  ['Achievements ', achievements],
                ],
              ),
            ],
          ),
        ),
      );
    }

    Directory? output;
    if (Platform.isAndroid) {
      // For Android, use the Downloads directory
      output = Directory('/storage/emulated/0/Download');
      if (!(await output.exists())) {
        output = await getExternalStorageDirectory();
      }
    } else if (Platform.isIOS) {
      // For iOS, use the application documents directory
      output = await getApplicationDocumentsDirectory();
    }

    final file = File(path.join(output!.path, 'curriculum_vitae.pdf'));
    await file.writeAsBytes(await pdf.save());
    print('PDF saved: ${file.path}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to ${file.path}')),
    );
  }

  /*Future<void> getFilePath(String filename) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    return join(appDocPath,filename);
  }*/

  Future<void> fetchUserData() async {
    User? user = auth.currentUser;
    String userId = user?.uid ?? '';

    DocumentReference userDocument = firestore.collection('users').doc(userId);

    userDocument.get().then((DocumentSnapshot document) {
      if (document.exists) {
        setState(() {
          emailController.text = document['email'];
          usernameController.text = document['displayName'];
          IDController.text = document['id_number'];
          highSchoolPasswordController.text = document['high_school'];
          tertiaryController.text = document['tertiary'];
          experienceController.text = document['experience'];
          biographyController.text = document['bio'];
          achievementController.text = document['achievements'];
        });
      } else {
        setState(() {
          emailController.text = "email";
          usernameController.text = "full name";
          IDController.text = "please enter your ID";
          highSchoolPasswordController.text =
              "where did you attend high school";
          tertiaryController.text = "where did you attend university";
          experienceController.text = "any experience";
          biographyController.text = "biography";
          achievementController.text = "any achievements";
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
                        labelText: "Enter full name"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: IDController,
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
                        hintText: "Enter your your ID number",
                        border: OutlineInputBorder(),
                        labelText: "please enter your ID number"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your ID number';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: highSchoolPasswordController,
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
                          Icons.school,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your high school backround",
                        border: OutlineInputBorder(),
                        labelText:
                            "when did you matriculate and in which subjects"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your high school background';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    onChanged: (text) {
                      //provider.fetchPredictiveText(text);
                    },
                    controller: experienceController,
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
                          Icons.factory,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your work experience",
                        border: OutlineInputBorder(),
                        labelText: "any work experience?"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your work experince';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Predicted Text:"),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: tertiaryController,
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
                          Icons.school,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your university background",
                        border: OutlineInputBorder(),
                        labelText: "university background"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your university background';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: biographyController,
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
                        labelText: "short biography"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your biography';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: achievementController,
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
                          Icons.card_giftcard,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your achievements and extra murals",
                        border: OutlineInputBorder(),
                        labelText: "any achievements and extra murals"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your achievements and extra murals';
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Navigate the user to the Home page
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill input')),
                          );
                        }
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _updateUserDetails(
                              usernameController.text,
                              emailController.text,
                              biographyController.text,
                              achievementController.text,
                              experienceController.text,
                              IDController.text,
                              highSchoolPasswordController.text,
                              tertiaryController.text);
                          // Navigate to a new page here
                        },
                        child: const Text('save'),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _generatePdf;
                        print("hello");
                        if (_formKey.currentState!.validate()) {
                          // Navigate the user to the Home page
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill input')),
                          );
                        }
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          // Navigate to a new page here
                          _generatePdf;
                          List<Map<String, dynamic>> data = await fetchData();
                          await generatePdf(data);
                          print("hello agian");
                        },
                        child: const Text('generate cv'),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          // Navigate the user to the Home page
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill input')),
                          );
                        }
                      },
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 20),
                            textStyle: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          // Navigate to a new page here
                          Route route = MaterialPageRoute(
                              builder: (context) => const ProfilePage(
                                    title: "Profile",
                                  ));
                          Navigator.push(context, route);
                        },
                        child: const Text('profile'),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Navigate the user to the Home page
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill input')),
                      );
                    }
                  },
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20),
                        textStyle: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      // Navigate to a new page here
                      Route route = MaterialPageRoute(
                          builder: (context) => const Login(
                                title: "Create CV",
                              ));
                      Navigator.push(context, route);
                      await FirebaseAuth.instance.signOut();
                      Fluttertoast.showToast(
                          msg: "log out successful",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 2,
                          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                          textColor: Colors.white,
                          fontSize: 16.0);
                    },
                    child: const Text('sign out'),
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
