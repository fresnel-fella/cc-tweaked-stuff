local aes = require("idarcryptocompressed").aes

-- AES-CBC encryption/decryption example
local key = "676767" -- don't matter the size of the key, it will be derived anyway lol
local data = "Sensitive information"
local iv = aes.generate_iv() -- 16 random bytes
local encrypted = aes.cbc_encrypt(data, key, iv)
local decrypted = aes.cbc_decrypt(encrypted, key)

printverbose(decrypted) -- Output: Sensitive information