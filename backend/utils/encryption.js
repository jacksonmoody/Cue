var crypto = require("crypto");

// Encryption algorithm
var ALGORITHM = "aes-256-gcm";
var IV_LENGTH = 16; // 16 bytes for AES
var SALT_LENGTH = 64; // 64 bytes for salt
var TAG_LENGTH = 16; // 16 bytes for GCM tag
var KEY_LENGTH = 32; // 32 bytes for AES-256

/**
 * Derives a key from the master encryption key using PBKDF2
 * @param {string} masterKey - The master encryption key from environment
 * @param {Buffer} salt - Salt for key derivation
 * @returns {Buffer} Derived key
 */
function deriveKey(masterKey, salt) {
  return crypto.pbkdf2Sync(masterKey, salt, 100000, KEY_LENGTH, "sha256");
}

/**
 * Encrypts a string value
 * @param {string} text - Plain text to encrypt
 * @param {string} masterKey - Master encryption key
 * @returns {string} Encrypted string (format: salt:iv:tag:encryptedData)
 */
function encrypt(text, masterKey) {
  if (!text) {
    return null;
  }

  if (!masterKey) {
    throw new Error("Encryption key is not configured");
  }

  // Generate random salt and IV
  var salt = crypto.randomBytes(SALT_LENGTH);
  var iv = crypto.randomBytes(IV_LENGTH);

  // Derive key from master key
  var key = deriveKey(masterKey, salt);

  // Create cipher
  var cipher = crypto.createCipheriv(ALGORITHM, key, iv);

  // Encrypt
  var encrypted = Buffer.concat([cipher.update(text, "utf8"), cipher.final()]);

  // Get authentication tag
  var tag = cipher.getAuthTag();

  // Combine salt, iv, tag, and encrypted data
  var result = Buffer.concat([salt, iv, tag, encrypted]);

  // Return as base64 string for easy storage
  return result.toString("base64");
}

/**
 * Decrypts an encrypted string
 * @param {string} encryptedText - Encrypted string (format: salt:iv:tag:encryptedData)
 * @param {string} masterKey - Master encryption key
 * @returns {string} Decrypted plain text
 */
function decrypt(encryptedText, masterKey) {
  if (!encryptedText) {
    return null;
  }

  if (!masterKey) {
    throw new Error("Encryption key is not configured");
  }

  try {
    // Decode from base64
    var data = Buffer.from(encryptedText, "base64");

    // Extract components
    var salt = data.slice(0, SALT_LENGTH);
    var iv = data.slice(SALT_LENGTH, SALT_LENGTH + IV_LENGTH);
    var tag = data.slice(
      SALT_LENGTH + IV_LENGTH,
      SALT_LENGTH + IV_LENGTH + TAG_LENGTH
    );
    var encrypted = data.slice(SALT_LENGTH + IV_LENGTH + TAG_LENGTH);

    // Derive key from master key
    var key = deriveKey(masterKey, salt);

    // Create decipher
    var decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
    decipher.setAuthTag(tag);

    // Decrypt
    var decrypted = Buffer.concat([
      decipher.update(encrypted),
      decipher.final(),
    ]);

    return decrypted.toString("utf8");
  } catch (err) {
    throw new Error("Failed to decrypt data: " + err.message);
  }
}

/**
 * Encrypts an object's sensitive fields
 * @param {Object} obj - Object containing sensitive fields
 * @param {Array<string>} fieldsToEncrypt - Array of field names to encrypt
 * @param {string} masterKey - Master encryption key
 * @returns {Object} Object with encrypted fields
 */
function encryptObject(obj, fieldsToEncrypt, masterKey) {
  if (!obj || typeof obj !== "object") {
    return obj;
  }

  var encrypted = { ...obj };
  for (var i = 0; i < fieldsToEncrypt.length; i++) {
    var field = fieldsToEncrypt[i];
    if (encrypted[field] !== undefined && encrypted[field] !== null) {
      encrypted[field] = encrypt(String(encrypted[field]), masterKey);
    }
  }
  return encrypted;
}

/**
 * Decrypts an object's sensitive fields
 * @param {Object} obj - Object containing encrypted fields
 * @param {Array<string>} fieldsToDecrypt - Array of field names to decrypt
 * @param {string} masterKey - Master encryption key
 * @returns {Object} Object with decrypted fields
 */
function decryptObject(obj, fieldsToDecrypt, masterKey) {
  if (!obj || typeof obj !== "object") {
    return obj;
  }

  var decrypted = { ...obj };
  for (var i = 0; i < fieldsToDecrypt.length; i++) {
    var field = fieldsToDecrypt[i];
    if (decrypted[field] !== undefined && decrypted[field] !== null) {
      try {
        decrypted[field] = decrypt(decrypted[field], masterKey);
      } catch (err) {
        console.error("Error decrypting field " + field + ":", err);
        // If decryption fails, set to null rather than crashing
        decrypted[field] = null;
      }
    }
  }
  return decrypted;
}

module.exports = {
  encrypt,
  decrypt,
  encryptObject,
  decryptObject,
};
