import 'package:bcrypt/bcrypt.dart';
void main() {
  // Check if hashes stored in DB match passwords
  // Replace these hashes with the actual ones from your DB
  print(BCrypt.checkpw('admin123', r'$2a$10$E9EAspT4J3SgipkObr/mJOWbltrq7.scVv5VcCTZvo5MsqZvOdjD4K'));
  print(BCrypt.checkpw('it123',    r'$2a$10$RBHj2HRFG1Xv5qqXKq048exLwcjuQfUZACJdNERkCVMeyzi2QIxT.jCuFbh6a'));
  print(BCrypt.checkpw('user123',  r'$2a$10$NcbNGLaC/59CEIl4rsKEKu59TxEMZk5ZAY8bcy'));
}
