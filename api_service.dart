import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'device_service.dart';

class ApiService {
  /// Dispatches the attendance payload over local Wi-Fi to the server endpoint
  static Future<Map<String, dynamic>> submitAttendance({
    required String targetUrl,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final studentId = prefs.getString('student_id') ?? '';
    final nationalId = prefs.getString('national_id') ?? '';
    final fullName = prefs.getString('full_name') ?? '';
    final deviceUuid = await DeviceService.getDeviceUuid();

    final payload = {
      'token': token,
      'student_id': studentId,
      'national_id': nationalId,
      'full_name': fullName,
      'device_uuid': deviceUuid,
    };

    try {
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Attendance verified!'};
      } else {
        return {'success': false, 'message': data['detail'] ?? 'Submission rejected.'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Cannot reach server. Ensure you are connected to the lecture Wi-Fi.'
      };
    }
  }
}
