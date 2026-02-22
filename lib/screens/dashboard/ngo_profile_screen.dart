import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NgoProfileScreen extends StatefulWidget {
  const NgoProfileScreen({super.key});

  @override
  State<NgoProfileScreen> createState() => _NgoProfileScreenState();
}

class _NgoProfileScreenState extends State<NgoProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController regController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  Map<String, dynamic> existingData = {};

  bool isLoading = true;
  bool isSaving = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  

  // 🔥 FETCH DATA FROM FIRESTORE
  Future<void> _loadProfile() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      existingData = doc.data()!;

      nameController.text = existingData['ngoName'] ?? '';
      phoneController.text = existingData['phone'] ?? '';
      addressController.text = existingData['address'] ?? '';
      regController.text = existingData['registrationNumber'] ?? '';
      aboutController.text = existingData['about'] ?? '';
    }

    setState(() => isLoading = false);
  }

  // 🔥 UPDATE ONLY CHANGED FIELDS
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    Map<String, dynamic> updatedData = {};

    if (nameController.text.trim() != existingData['ngoName']) {
      updatedData['ngoName'] = nameController.text.trim();
    }

    if (phoneController.text.trim() != existingData['phone']) {
      updatedData['phone'] = phoneController.text.trim();
    }

    if (addressController.text.trim() != existingData['address']) {
      updatedData['address'] = addressController.text.trim();
    }

    if (regController.text.trim() != existingData['registrationNumber']) {
      updatedData['registrationNumber'] = regController.text.trim();
    }

    if (aboutController.text.trim() != existingData['about']) {
      updatedData['about'] = aboutController.text.trim();
    }

    updatedData['updatedAt'] = FieldValue.serverTimestamp();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .set(updatedData, SetOptions(merge: true));

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Updated Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "NGO Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildField("NGO Name", nameController),
              _buildField("Phone", phoneController),
              _buildField("Address", addressController),
              _buildField("Registration Number", regController),
              _buildField("About NGO", aboutController, maxLines: 3),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "SAVE CHANGES",
                        style: TextStyle(
                          color: Color.fromRGBO(255, 255, 255, 1),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        validator: (value) =>
            value == null || value.isEmpty ? "Required field" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
