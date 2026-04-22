import 'package:encrypt/encrypt.dart' as crypto;

class AesCipher {
  const AesCipher._();

  static String encrypt(String plainText, String secretKey) {
    final normalizedKey = _normalizeKey(secretKey);
    final key = crypto.Key.fromUtf8(normalizedKey);
    final aes = crypto.AES(
      key,
      mode: crypto.AESMode.ecb,
      padding: 'PKCS7',
    );
    final encrypter = crypto.Encrypter(aes);
    return encrypter.encrypt(
      plainText,
      iv: crypto.IV.fromLength(16),
    ).base64;
  }

  static String _normalizeKey(String raw) {
    final value = raw.trim();
    if (value.length == 16 || value.length == 24 || value.length == 32) {
      return value;
    }
    if (value.length > 32) {
      return value.substring(0, 32);
    }
    return value.padRight(16, '0');
  }
}
