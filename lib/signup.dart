import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final plateController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? selectedVehicleType;

  bool hidePassword = true;
  bool isLoading = false;

  final List<String> vehicleTypes = [
    'Car',
    'Motorcycle',
    'Van',
    'Lorry',
    'Bus',
    'Other',
  ];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    plateController.dispose();
    super.dispose();
  }

  //SIGN UP
  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedVehicleType == null) {
      showMessage('Please select your vehicle type.');
      return;
    }

    setState(() => isLoading = true);

    String currentStep = 'Creating Authentication account';

    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final authUID = credential.user!.uid;

      debugPrint('STEP 1 SUCCESS: Authentication account created.');

      final counterRef =
          FirebaseFirestore.instance.collection('id_counters').doc('main');

      final userRef =
          FirebaseFirestore.instance.collection('user').doc(authUID);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final counterSnapshot = await transaction.get(counterRef);
        final counterData = counterSnapshot.data() ?? {};

        final nextUserNumber = (counterData['user'] as num?)?.toInt() ?? 0;

        final nextVehicleNumber =
            (counterData['vehicle'] as num?)?.toInt() ?? 0;

        final newUserNumber = nextUserNumber + 1;
        final newVehicleNumber = nextVehicleNumber + 1;

        final userID = 'U${newUserNumber.toString().padLeft(3, '0')}';
        final vehicleID = 'V${newVehicleNumber.toString().padLeft(3, '0')}';

        final vehicleRef =
            FirebaseFirestore.instance.collection('vehicle').doc(vehicleID);

        transaction.set(counterRef, {
          'user': newUserNumber,
          'vehicle': newVehicleNumber,
        });

        transaction.set(userRef, {
          'userID': userID,
          'authUID': authUID,
          'username': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.set(vehicleRef, {
          'vehicleID': vehicleID,
          'userID': userID,
          'authUID': authUID,
          'vehicle_type': selectedVehicleType,
          'vehicle_status': 'Active',
          'plate_number': plateController.text.trim().toUpperCase(),
          'last_sync': null,
        });

        debugPrint('Generated User ID: $userID');
        debugPrint('Generated Vehicle ID: $vehicleID');
      });

      if (!mounted) return;

      showMessage('Account registered successfully!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('AUTHENTICATION ERROR: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');

      showMessage('Authentication Error: ${e.code}');
    } on FirebaseException catch (e) {
      debugPrint('FIREBASE ERROR AT: $currentStep');
      debugPrint('ERROR CODE: ${e.code}');
      debugPrint('ERROR MESSAGE: ${e.message}');

      showMessage('Error at $currentStep: ${e.code}');
    } catch (e, stackTrace) {
      debugPrint('GENERAL ERROR AT: $currentStep');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF142B4A);
    const blue = Color(0xFF2878D0);
    const grey = Color(0xFF7A8795);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: navy,
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.directions_car_rounded,
                        size: 55,
                        color: navy,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Join BLINK',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Create your account to get started.',
                        style: TextStyle(
                          fontSize: 14,
                          color: grey,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Full Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: nameController,
                  decoration: inputDecoration(
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: inputDecoration(
                    hint: 'Enter your email',
                    icon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(value.trim())) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Phone Number',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration(
                    hint: 'Enter your phone number',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number.';
                    }
                    if (!RegExp(r'^[0-9+\-\s]{8,15}$').hasMatch(value.trim())) {
                      return 'Please enter a valid phone number.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: inputDecoration(
                    hint: 'Create your password',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password.';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                const Text(
                  'Vehicle Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Vehicle Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedVehicleType,
                  decoration: inputDecoration(
                    hint: 'Select vehicle type',
                    icon: Icons.directions_car_outlined,
                  ),
                  items: vehicleTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedVehicleType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your vehicle type.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 18),

                const Text(
                  'Vehicle Plate Number',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: navy,
                  ),
                ),

                const SizedBox(height: 8),

                TextFormField(
                  controller: plateController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: inputDecoration(
                    hint: 'e.g. ABC1234',
                    icon: Icons.pin_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your vehicle plate number.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: grey),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
