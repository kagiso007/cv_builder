import 'package:flutter/material.dart';
import 'package:cv_builder/login.dart';
import 'package:cv_builder/api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cv_builder/profilepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/pdf.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:cv_builder/loading.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

void _updateUserDetails(
    String fullName,
    String email,
    String biography,
    String achievements,
    String experience,
    String idNumber,
    String highSchool,
    String tertiary,
    String phoneNumber,
    String address,
    String gender,
    String dateOfBirth,
    String nationality,
    String race,
    String disability,
    String language,
    String skills,
    String references) {
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
    'phoneNumber': phoneNumber,
    'address': address,
    'gender': gender,
    'dateOfBirth': dateOfBirth,
    'nationality': nationality,
    'race': race,
    'disability': disability,
    'language': language,
    'skills': skills,
    'references': references,
  }, SetOptions(merge: true));
}

class _HomePageState extends State<HomePage> {
  var displayFile = "";
  APIKEY apikey = APIKEY();
  Loadings showLoaderDialog = Loadings();
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  late GenerativeModel model;
  TextEditingController experienceController = TextEditingController();
  Timer? _debounce;

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Perform the search operation here
    });
  }

  generate() async {
    final prompt = [
      Content.text(
          'complete the following sentence with one word:${experienceController.text}')
    ];
    final response = await model.generateContent(prompt);
    setState(() {
      predicted_text = response.text!;
    });
    print(response.text);
  }

  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController usernameController = TextEditingController();
  TextEditingController IDController = TextEditingController();
  TextEditingController highSchoolPasswordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController tertiaryController = TextEditingController();
  TextEditingController biographyController = TextEditingController();
  TextEditingController achievementController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController nationalityController = TextEditingController();
  TextEditingController raceController = TextEditingController();
  TextEditingController disabilityController = TextEditingController();
  TextEditingController languageController = TextEditingController();
  TextEditingController skillsController = TextEditingController();
  TextEditingController referencesController = TextEditingController();

  final String password = "";
  bool isLoading = false;
  final String photoURL = "";
  String message = '';
  String predicted_text = '';

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    User? user = auth.currentUser;
    String userId = user?.uid ?? '';
    List<Map<String, dynamic>> users = [];
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection(userId).get();

    for (var doc in snapshot.docs) {
      users.add(doc.data() as Map<String, dynamic>);
    }

    return users;
  }

  @override
  void initState() {
    model = GenerativeModel(model: 'gemini-pro', apiKey: apikey.apiKey);
    super.initState();
    fetchUserData();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> generatePdf(List<Map<String, dynamic>> data) async {
    final pdf = pw.Document();

    for (var item in data) {
      // Extract specific attributes from Firestore document
      String name = item['displayName'] ?? "";
      String email = item['email'] ?? "";
      String bio = item['bio'] ?? "";
      String idNumber = item['id_number'] ?? "";
      String highSchool = item['high_school'] ?? "";
      String tertiary = item['tertiary'] ?? "";
      String achievements = item['achievements'] ?? "";
      String skills = item['skills'] ?? "";
      String dateOfBirth = item['dateOfBirth'] ?? "";
      String phoneNumber = item['phoneNumber'] ?? "";
      String address = item['address'] ?? "";
      String nationality = item['nationality'] ?? "";
      String race = item['race'] ?? "";
      String gender = item['gender'] ?? "";
      String disability = item['disability'] ?? "";
      String language = item['language'] ?? "";
      String experience = item['experience'] ?? "";
      String references = item['references'] ?? "";
      final imageUrl = item['photoUrl'] ?? "";
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
                  ['Nationality ', nationality],
                  ['Address ', address],
                  ['Phone ', phoneNumber],
                  ['Date of Birth ', dateOfBirth],
                  ['language', language],
                  ['Gender ', gender],
                  ['high_school ', highSchool],
                  ['higher education ', tertiary],
                  ['Achievements ', achievements],
                  ['skills', skills],
                  ['race ', race],
                  ['disability ', disability],
                  ['experience ', experience],
                  ['references ', references],
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
    String pathToWrite = '${output.path}/curriculum_vitae.pdf';
    File outputFile = File(pathToWrite);
    outputFile.writeAsBytesSync(await pdf.save());
    displayFile = pathToWrite;

    print('PDF saved: ${file.path}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to ${file.path}')),
    );
  }

  void openFile() {
    OpenFile.open(displayFile);
  }

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
          skillsController.text = document['skills'];
          referencesController.text = document['references'];
          phoneNumberController.text = document['phoneNumber'];
          addressController.text = document['address'];
          dateOfBirthController.text = document['dateOfBirth'];
          genderController.text = document['gender'];
          nationalityController.text = document['nationality'];
          languageController.text = document['language'];
          disabilityController.text = document['disability'];
          raceController.text = document['race'];
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
          skillsController.text = 'skills';
          referencesController.text = 'references';
          phoneNumberController.text = 'phone_number';
          addressController.text = 'address';
          dateOfBirthController.text = 'date_of_birth';
          genderController.text = 'gender';
          nationalityController.text = 'nationality';
          languageController.text = 'language';
          disabilityController.text = 'disability';
          raceController.text = 'race';
        });
      }
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    _debounce?.cancel();
    experienceController.dispose();
    super.dispose();
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
                    controller: dateOfBirthController,
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
                        hintText: "Enter your your date of birth",
                        border: OutlineInputBorder(),
                        labelText: "please enter your date of birth"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your date of birth';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: languageController,
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
                          Icons.speaker_notes,
                          color: Colors.blue,
                        ),
                        hintText: "Enter languages",
                        border: OutlineInputBorder(),
                        labelText: "please enter languages"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your languages';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: raceController,
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
                        hintText: "Enter your race",
                        border: OutlineInputBorder(),
                        labelText: "please enter race"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter race';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: nationalityController,
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
                          Icons.flag,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your nationality",
                        border: OutlineInputBorder(),
                        labelText: "please enter nationality"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter nationality';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: genderController,
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
                        hintText: "Enter your gender",
                        border: OutlineInputBorder(),
                        labelText: "please enter your gender"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your gender';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: addressController,
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
                          Icons.home,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your address",
                        border: OutlineInputBorder(),
                        labelText: "please enter your address"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: phoneNumberController,
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
                          Icons.phone,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your phone Number",
                        border: OutlineInputBorder(),
                        labelText: "please enter your phone Number"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone Number';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: disabilityController,
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
                          Icons.local_hospital,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your disabilities",
                        border: OutlineInputBorder(),
                        labelText: "please enter your disabilities"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your disabilities';
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
                    enableSuggestions: true,
                    onChanged: (text) {
                      generate();
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
                Text(predicted_text),
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
                          Icons.star,
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
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: skillsController,
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
                          Icons.work,
                          color: Colors.blue,
                        ),
                        hintText: "Enter your skills",
                        border: OutlineInputBorder(),
                        labelText: "please enter your skills"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your skills';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: TextFormField(
                    controller: referencesController,
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
                        hintText: "Enter your references",
                        border: OutlineInputBorder(),
                        labelText: "please enter your references"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your references';
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
                            tertiaryController.text,
                            phoneNumberController.text,
                            addressController.text,
                            genderController.text,
                            dateOfBirthController.text,
                            nationalityController.text,
                            raceController.text,
                            disabilityController.text,
                            languageController.text,
                            skillsController.text,
                            referencesController.text,
                          );
                          // Navigate to a new page here

                          Fluttertoast.showToast(
                              msg: "details saved successfully",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 2,
                              backgroundColor:
                                  const Color.fromARGB(255, 0, 0, 0),
                              textColor: Colors.white,
                              fontSize: 16.0);
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
                      onPressed: () async {
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
                          Loadings.showLoading(context, _keyLoader);
                          User? user = auth.currentUser;
                          String userId = user?.uid ?? '';
                          List<Map<String, dynamic>> currentUser = [];
                          final CollectionReference collectionReference =
                              FirebaseFirestore.instance.collection('users');
                          final documents = await collectionReference
                              .where("id", isEqualTo: userId)
                              .get();
                          for (var element in documents.docs) {
                            currentUser
                                .add(element.data() as Map<String, dynamic>);
                          }
                          await generatePdf(currentUser);
                          Navigator.of(_keyLoader.currentContext!,
                                  rootNavigator: true)
                              .pop();
                          openFile();
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
