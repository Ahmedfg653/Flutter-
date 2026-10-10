import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_service.dart';
import 'scanner_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _nationalIdController = TextEditingController();
  bool _isLoading = false;

  void _completeEnrollment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('full_name', _nameController.text.trim());
    await prefs.setString('student_id', _studentIdController.text.trim());
    await prefs.setString('national_id', _nationalIdController.text.trim());
    
    // Generate and permanently store device hardware UUID
    await DeviceService.getDeviceUuid();
    
    // Permanently lock enrollment - no logout or re-registration
    await prefs.setBool('is_enrolled', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student One-Time Registration'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.school, size: 70, color: Colors.blueAccent),
              const SizedBox(height: 16),
              const Text(
                'Device Hardware Binding',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: This device will be permanently bound to your academic record. You cannot register multiple accounts or log out once completed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name (as in University Records)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'University Student ID',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nationalIdController,
                decoration: const InputDecoration(
                  labelText: 'National ID / Passport Number',
                  prefixIcon: Icon(Icons.credit_card),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().length < 8 ? 'Enter valid ID' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _completeEnrollment,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Bind Device & Open Scanner', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
