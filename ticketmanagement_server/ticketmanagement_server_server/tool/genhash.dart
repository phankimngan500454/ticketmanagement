import 'package:bcrypt/bcrypt.dart';

void main() {
  final adminHash = BCrypt.hashpw('admin123', BCrypt.gensalt());
  final itHash    = BCrypt.hashpw('it123',    BCrypt.gensalt());
  final userHash  = BCrypt.hashpw('user123',  BCrypt.gensalt());
  print(adminHash);
  print(itHash);
  print(userHash);
}
