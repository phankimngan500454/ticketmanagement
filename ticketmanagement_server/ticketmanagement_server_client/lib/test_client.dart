import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
void main() async {
  var client = Client('http://127.0.0.1:8080/');
  try {
    await client.auth.login('admin', 'password');
    print('Login success');
  } catch (e) {
    print('Error: $e');
  }
}