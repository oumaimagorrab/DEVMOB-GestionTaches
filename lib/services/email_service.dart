import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Exemple avec SendGrid
  static Future<bool> sendInvitationEmail({
    required String toEmail,
    required String projectName,
    required String inviterName,
    required String invitationLink,
  }) async {
    try {
      // Configuration SendGrid
      const String sendGridApiKey = 'YOUR_SENDGRID_API_KEY';
      
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Authorization': 'Bearer $sendGridApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'personalizations': [
            {
              'to': [
                {'email': toEmail}
              ],
              'subject': 'Invitation à rejoindre le projet $projectName',
            }
          ],
          'from': {'email': 'noreply@votreapp.com', 'name': 'Gestion Tâches'},
          'content': [
            {
              'type': 'text/html',
              'value': '''
                <h2>Vous êtes invité !</h2>
                <p>$inviterName vous invite à rejoindre le projet <strong>$projectName</strong>.</p>
                <p><a href="$invitationLink" style="padding: 12px 24px; background: #6B4EFF; color: white; text-decoration: none; border-radius: 8px;">Rejoindre le projet</a></p>
              '''
            }
          ],
        }),
      );
      
      return response.statusCode == 202;
    } catch (e) {
      print('Erreur envoi email: $e');
      return false;
    }
  }

  // Alternative avec Firebase Functions
  static Future<bool> sendViaFirebase({
    required String email,
    required String projectName,
  }) async {
    // Implémentation Firebase Cloud Functions
    // À déployer côté serveur pour sécurité
    return true;
  }
}