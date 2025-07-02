import 'dart:io';
import 'dart:convert';
import 'package:chokchey_hr_app/constants/constant.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../../localization/language.dart';
import 'package:image_picker/image_picker.dart';
import '../../localization/language_logic.dart';
import '../../widgets/InputFormField.dart';
import '../../widgets/RoundedButton.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  double screenWidth = 0;
  double screenHeight = 0;
  Language language = Language();
  bool showLoading = false;

  var firstNameController = TextEditingController();
  var lastNameController = TextEditingController();
  var phoneNumberController = TextEditingController();
  var passwordController = TextEditingController();
  var confirmPasswordController = TextEditingController();
  var bankNameController = TextEditingController();
  var accountNameController = TextEditingController();
  var accountNumberController = TextEditingController();
  var selectedStaffType = "";
  var selectUserType = "";
  String staffIdCard = "";

  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        final bytes = File(pickedFile.path).readAsBytesSync();
        staffIdCard = "data:image/png;base64,${base64Encode(bytes)}";
      } else {
        print('No image selected.');
      }
    });
  }

  void _showOptionsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  title: Center(
                    child: Text(
                      "Choose Image",
                      style: const TextStyle(
                        color: Color(primary),
                        fontFamily: 'Khmer OS',
                      ),
                    ),
                  ),
                  onTap: () {
                    _getImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(color: Color(primary), thickness: 0.2),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera,
                    color: Color(primary),
                  ),
                  title: Text("Camera"),
                  onTap: () {
                    _getImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(primary),
                  ),
                  title: Text("Gallery"),
                  onTap: () {
                    _getImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    language = context.watch<LanguageLogic>().language;

    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.grey[50],
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
              onPressed: () => Navigator.of(context).pop(),
            ),
            elevation: 0,
            title: Text(
              language.register,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth / 20,
                color: Colors.black,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: Container(child: _buildBody(context, isKeyboardVisible)),
        );
      },
    );
  }

  Widget _buildBody(context, isKeyboardVisible) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InputFormField(
            height: 55,
            hint: "First Name",
            controller: firstNameController,
            icon: FontAwesomeIcons.solidUser,
          ),
          InputFormField(
            height: 55,
            hint: "Last Name",
            controller: lastNameController,
            icon: FontAwesomeIcons.solidUser,
          ),
          InputFormField(
            height: 55,
            hint: "Phone Number",
            number: true,
            controller: phoneNumberController,
            icon: FontAwesomeIcons.phone,
          ),
          InputFormField(
            height: 55,
            hint: "Bank Name",
            number: false,
            controller: bankNameController,
            icon: FontAwesomeIcons.warehouse,
          ),
          InputFormField(
            height: 55,
            hint: "Account Number",
            number: true,
            controller: accountNumberController,
            icon: FontAwesomeIcons.userCheck,
          ),
          InputFormField(
            height: 55,
            hint: "Account Name",
            number: false,
            controller: accountNameController,
            icon: FontAwesomeIcons.wallet,
          ),
          InputFormField(
            height: 55,
            hint: "Password",
            isObscureText: true,
            controller: passwordController,
            icon: FontAwesomeIcons.lock,
          ),
          InputFormField(
            height: 55,
            hint: "Confirm Password",
            isObscureText: true,
            controller: confirmPasswordController,
            icon: FontAwesomeIcons.lock,
          ),
          !isKeyboardVisible
              ? SizedBox(height: screenHeight / 20)
              : SizedBox(height: screenHeight / 15),
          Container(
            margin: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              bottom: 20.0,
            ),
            width: screenWidth,
            child: RoundedButton(
              roundSize: screenWidth / 22,
              color: const Color(primary),
              btnWith: screenWidth,
              btnText: "Register",
              onBtnPressed:
                  () => () {
                    print("Hello World");
                  },
            ),
          ),
        ],
      ),
    );
  }
}
