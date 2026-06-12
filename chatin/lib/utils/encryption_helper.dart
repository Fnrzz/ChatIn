import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionHelper {
  // Ambil key dari .env, atau gunakan key default fallback (untuk safety)
  static final String _keyString = dotenv.env['ENCRYPTION_KEY'] ?? 'my32lengthsupersecretnooneknows1';
  
  // Pastikan panjang key tepat 32 byte untuk algoritma AES-256
  static final _key = encrypt.Key.fromUtf8(_keyString.padRight(32, '0').substring(0, 32));
  
  // Initialization Vector statis. Kita mengambil 16 byte pertama dari _keyString (dari .env)
  // agar tetap konstan di setiap sesi aplikasi, menghindari bug gagal dekripsi setelah restart.
  static final _iv = encrypt.IV.fromUtf8(_keyString.padRight(16, '0').substring(0, 16));
  
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  /// Mengenkripsi teks sebelum dikirim ke Supabase
  static String encryptText(String plainText) {
    if (plainText.isEmpty) return plainText;
    try {
      return _encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      print('Encryption error: $e');
      return plainText;
    }
  }

  /// Mendekripsi teks setelah diambil dari Supabase
  static String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    try {
      return _encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      // Jika error (misalnya teks adalah plain text lama yang belum terenkripsi), kembalikan aslinya
      return encryptedText;
    }
  }
}
