function sha()
    local sha = {}

    local H = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    }
    local K = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
        0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
        0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
        0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
        0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
        0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
        0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
        0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    }

    local MOD32 = 0x100000000
    local B = 64
    local IPAD = string.rep("\x36", 64)
    local OPAD = string.rep("\x5c", 64)

    local function rotr32(value, bits)
        value = value % MOD32
        local r = (bit32.rshift(value, bits) + bit32.lshift(value, 32 - bits)) % MOD32
        return r
    end

    local function to32(x)
        return x % MOD32
    end

    local function sha256_compress(chunk, H_copy)
        local W = {}
        for i = 1, 16 do
            W[i] = to32(chunk[i] or 0)
        end
        for i = 17, 64 do
            local w15 = W[i-15]
            local w2  = W[i-2]
            local s0 = bit32.bxor(bit32.bxor(rotr32(w15, 7), rotr32(w15, 18)), bit32.rshift(w15, 3))
            local s1 = bit32.bxor(bit32.bxor(rotr32(w2, 17), rotr32(w2, 19)), bit32.rshift(w2, 10))
            W[i] = to32(W[i-16] + s0 + W[i-7] + s1)
        end

        local a, b, c, d, e, f, g, h = table.unpack(H_copy)

        for i = 1, 64 do
            local S1 = bit32.bxor(bit32.bxor(rotr32(e, 6), rotr32(e, 11)), rotr32(e, 25))
            local ch = bit32.bxor(bit32.band(e,f), bit32.band(bit32.bnot(e), g))
            local temp1 = to32(h + S1 + ch + K[i] + W[i])
            local S0 = bit32.bxor(bit32.bxor(rotr32(a, 2), rotr32(a, 13)), rotr32(a, 22))
            local maj = bit32.bxor(bit32.bxor(bit32.band(a, b), bit32.band(a, c)), bit32.band(b, c))
            local temp2 = to32(S0 + maj)

            h = g
            g = f
            f = e
            e = to32(d + temp1)
            d = c
            c = b
            b = a
            a = to32(temp1 + temp2)
        end

        local t = {a,b,c,d,e,f,g,h}
        for i = 1, 8 do
            H_copy[i] = to32(H_copy[i] + t[i])
        end
    end

    function sha.sha256(message)
        local message_len = #message
        local padded_message = message .. "\128"
        while (#padded_message % 64) ~= 56 do
            padded_message = padded_message .. "\0"
        end

        padded_message = padded_message .. string.pack(">I8", message_len * 8)

        local H_copy = {table.unpack(H)}
        for pos = 1, #padded_message, 64 do
            local block = padded_message:sub(pos, pos + 63)
            local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p = string.unpack(">I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", block)
            local chunk = {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p}
            sha256_compress(chunk, H_copy)
        end

        local digest_hex = ""
        local digest_bin = ""
        for i = 1, 8 do
            digest_bin = digest_bin .. string.pack(">I4", H_copy[i]) 
            digest_hex = digest_hex .. string.format("%08x", H_copy[i])
        end
        return digest_hex, digest_bin
    end

    function sha.hmac_sha256(key, message, bin)
        local K_prime
        if #key > B then
            local _, K_hash_bin = sha.sha256(key)
            K_prime = K_hash_bin
        elseif #key < B then
            K_prime = key .. string.rep("\0", B - #key)
        else
            K_prime = key
        end

        local inner_key = {}
        for i = 1, B do
            inner_key[i] = string.char(bit32.bxor(K_prime:byte(i), IPAD:byte(i)))
        end

        local _, inner_hash_bin = sha.sha256(table.concat(inner_key) .. message)

        local outer_key = {}
        for i = 1, B do
            outer_key[i] = string.char(bit32.bxor(K_prime:byte(i), OPAD:byte(i)))
        end

        local result_hex, result_bin = sha.sha256(table.concat(outer_key) .. inner_hash_bin)
        return bin and result_bin or result_hex
    end


    return sha
end











local sha = sha()
function aeslib()
    local aes = {}

    local S_BOX = {
        0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
        0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0,
        0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15,
        0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75,
        0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84,
        0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf,
        0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
        0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2,
        0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73,
        0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb,
        0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79,
        0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
        0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a,
        0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e,
        0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf,
        0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16
    }

    local INV_S_BOX = {
        0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
        0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
        0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
        0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
        0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
        0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
        0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
        0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
        0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
        0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
        0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
        0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
        0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
        0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
        0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
        0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d
    }

    local RCON = {
        0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36
    }

    local function derive_key(secret)
        local _, bin = sha.sha256(secret)
        return bin:sub(17,32)
    end

    local function bxor(...)
        local args = {...}
        local result = args[1]
        for i = 2, #args do
            result = bit.bxor(result, args[i])
        end
        return result
    end

    local function xor(block1, block2)
        local result = {}
        for i = 1, #block1 do
            result[i] = string.char(bit.bxor(string.byte(block1, i), string.byte(block2, i)))
        end
        return table.concat(result)
    end

    local function to_matrix(plainText)
        local matrix = {}
        for i = 1, 4 do
            matrix[i] = {}
            for j = 1, 4 do
                matrix[i][j] = string.byte(plainText, (j - 1) * 4 + i)
            end
        end
        return matrix
    end

    local function from_matrix(matrix)
        local block = {}
        for i = 1, 4 do
            for j = 1, 4 do
                block[#block + 1] = string.char(matrix[j][i])
            end
        end

        return table.concat(block)
    end


    local function gmul(a, b)
        local return_value = 0
        local temp = 0
        while a ~= 0 do
            if bit.band(a, 1) ~= 0 then
                return_value = bit.bxor(return_value, b)
            end
            temp = bit.band(b, 0x80)
            b = bit.blshift(b, 1)
            if temp ~= 0 then
                b = bit.bxor(b, 0x1b)
            end
            a = bit.brshift(bit.band(a, 0xff), 1)
        end
        return bit.band(return_value, 0xff)
    end

    local function rot_word(word)
        return { word[2], word[3], word[4], word[1]}
    end

    local function sub_word(word)
        local newWord = {}
        for i = 1, 4 do
            local hex = string.byte(word[i]) + 1
            newWord[i] = S_BOX[hex]
        end
        return newWord
    end

    local function xor_word(wordA, wordB)
        local newWord = {}
        for i = 1, 4 do
            newWord[i] = bit.bxor(wordA[i], wordB[i])
        end
        return newWord
    end

    local function key_expansion(key)
        local round_keys = {}
        round_keys[1] = to_matrix(key)
        local rcon_index = 1

        for round = 2, 11 do
            round_keys[round] = {}
            local temp = round_keys[round - 1][4]
            temp = rot_word(temp)
            temp = sub_word(temp)
            temp[1] = bit.bxor(temp[1], RCON[rcon_index])
            rcon_index = rcon_index + 1
            local w_i_minus_4 = round_keys[round - 1][1]
            round_keys[round][1] = xor_word(w_i_minus_4, temp)

            for row = 2, 4 do
                temp = round_keys[round][row - 1]
                w_i_minus_4 = round_keys[round - 1][row]
                round_keys[round][row] = xor_word(w_i_minus_4, temp)
            end
        end

        return round_keys
    end

    local function sub_bytes(block, decrypt)
        local box = decrypt and INV_S_BOX or S_BOX

        local new_block = {}
        for i = 1, 4 do
            new_block[i] = {}
            for j = 1, 4 do
                new_block[i][j] = box[block[i][j] + 1]
            end
        end
        return new_block
    end

    local function shift_rows(block)
        block[2] = {block[2][2], block[2][3], block[2][4], block[2][1]}

        block[3] = {block[3][3], block[3][4], block[3][1], block[3][2]}

        block[4] = {block[4][4], block[4][1], block[4][2], block[4][3]}
    end

    local function inv_shift_rows(block)
        block[2] = {block[2][4], block[2][1], block[2][2], block[2][3]}

        block[3] = {block[3][3], block[3][4], block[3][1], block[3][2]}

        block[4] = {block[4][2], block[4][3], block[4][4], block[4][1]}
    end

    local function mix_columns(state, decrypt)
        local temp = {}
        for i = 1, 4 do
            local s0 = state[1][i]
            local s1 = state[2][i]
            local s2 = state[3][i]
            local s3 = state[4][i]

            if decrypt then
                temp[1] = bxor(gmul(0x0e, s0), gmul(0x0b, s1), gmul(0x0d, s2), gmul(0x09, s3))
                temp[2] = bxor(gmul(0x09, s0), gmul(0x0e, s1), gmul(0x0b, s2), gmul(0x0d, s3))
                temp[3] = bxor(gmul(0x0d, s0), gmul(0x09, s1), gmul(0x0e, s2), gmul(0x0b, s3))
                temp[4] = bxor(gmul(0x0b, s0), gmul(0x0d, s1), gmul(0x09, s2), gmul(0x0e, s3))
            else
                temp[1] = bxor(gmul(0x02, s0), gmul(0x03, s1), gmul(0x01, s2), gmul(0x01, s3))
                temp[2] = bxor(gmul(0x01, s0), gmul(0x02, s1), gmul(0x03, s2), gmul(0x01, s3))
                temp[3] = bxor(gmul(0x01, s0), gmul(0x01, s1), gmul(0x02, s2), gmul(0x03, s3))
                temp[4] = bxor(gmul(0x03, s0), gmul(0x01, s1), gmul(0x01, s2), gmul(0x02, s3))
            end

            for j = 1, 4 do
                state[j][i] = temp[j]
            end
        end
    end

    local function add_round_key(block, round_key)
        for i = 1, 4 do
            for j = 1, 4 do
                block[i][j] = bit.bxor(block[i][j], round_key[i][j])
            end
        end
    end

    local function encryptBlock(block, round_keys)
        block = to_matrix(block)
        add_round_key(block, round_keys[1])

        for round = 2, 11 do
            block = sub_bytes(block)
            shift_rows(block)

            if round < 11 then
                mix_columns(block)
            end

            add_round_key(block, round_keys[round])
        end
        return from_matrix(block)
    end


    local function decryptBlock(block, round_keys)
        block = to_matrix(block)
        add_round_key(block, round_keys[11])

        for round = 10, 1, -1 do
            inv_shift_rows(block)
            block = sub_bytes(block, true)

            add_round_key(block, round_keys[round])

            if round > 1 then
                mix_columns(block, true)
            end
        end
        return from_matrix(block)
    end

    function aes.cbc_encrypt(message, secret, iv)
        local key = derive_key(secret)
        key = key_expansion(key)

        if not iv or #iv ~= 16 then
            local temp_iv = {}
            for _ = 1, 16 do
                temp_iv[#temp_iv + 1] = string.char(math.random(0, 255))
            end
            iv = table.concat(temp_iv)
        end

        local remainder = #message % 16
        local fill_length = (remainder == 0) and 16 or (16 - remainder)
        message = message .. string.rep(string.char(fill_length), fill_length)

        local blocks = {}
        for i = 1, #message, 16 do
            table.insert(blocks, message:sub(i, i + 15))
        end

        local prev = iv
        local encrypted_message = ""

        for _, block in ipairs(blocks) do
            local xorBlock = xor(block, prev)
            local encrypted_block = encryptBlock(xorBlock, key)
            encrypted_message = encrypted_message .. encrypted_block
            prev = encrypted_block
        end

        return iv .. encrypted_message
    end

    function aes.cbc_decrypt(message, secret)
        local key = derive_key(secret)
        key = key_expansion(key)

        local iv = message:sub(1, 16)
        message = message:sub(17)

        local blocks = {}
        for i = 1, #message, 16 do
            table.insert(blocks, message:sub(i, i + 15))
        end

        local prev = iv
        local decrypted_message = ""

        for _, block in ipairs(blocks) do
            local decrypted_block = decryptBlock(block, key)
            local xorBlock = xor(decrypted_block, prev)
            decrypted_message = decrypted_message .. xorBlock
            prev = block
        end

        local fill_length = string.byte(decrypted_message:sub(-1))
        if fill_length >= 1 and fill_length <= 16 then
            decrypted_message = decrypted_message:sub(1, -fill_length - 1)
        end

        return decrypted_message
    end

    function aes.generate_iv()
        local t = {}
        for i = 1, 16 do t[i] = string.char(math.random(0,255)) end
        return table.concat(t)
    end

    return aes
end
local aes = aeslib()









function chachalib()
    local chacha = {}

    local function to_u32(x) return x % 2^32 end

    local function word_to_bytes_le(w)
        w = to_u32(w)
        local b1 = w % 256
        local b2 = math.floor(w / 256) % 256
        local b3 = math.floor(w / 65536) % 256
        local b4 = math.floor(w / 16777216) % 256
        return string.char(b1, b2, b3, b4)
    end

    local function bytes_to_word_le(s, i)
        i = i or 1
        local b1, b2, b3, b4 = string.byte(s, i, i+3)
        return to_u32(b1 + b2*256 + b3*65536 + b4*16777216)
    end

    local function rotl32(x, n)
        x = to_u32(x)
        n = n % 32
        return to_u32(bit32.lshift(x, n) + bit32.rshift(x, 32 - n))
    end

    local function quarter_round(state, a, b, c, d)
        state[a] = to_u32(state[a] + state[b]); state[d] = bit32.bxor(state[d], state[a]); state[d] = rotl32(state[d], 16)
        state[c] = to_u32(state[c] + state[d]); state[b] = bit32.bxor(state[b], state[c]); state[b] = rotl32(state[b], 12)
        state[a] = to_u32(state[a] + state[b]); state[d] = bit32.bxor(state[d], state[a]); state[d] = rotl32(state[d], 8)
        state[c] = to_u32(state[c] + state[d]); state[b] = bit32.bxor(state[b], state[c]); state[b] = rotl32(state[b], 7)
    end

    local function chacha20_block(key32, counter, nonce12)
        local constants = {
            bytes_to_word_le("expa"),
            bytes_to_word_le("nd 3"),
            bytes_to_word_le("2-by"),
            bytes_to_word_le("te k"),
        }

        local state = {}
        for i = 1,4 do state[i] = constants[i] end
        for i = 1,8 do
            local offset = (i-1)*4 + 1
            state[4 + i] = bytes_to_word_le(key32, offset)
        end
        state[13] = to_u32(counter)
        state[14] = bytes_to_word_le(nonce12, 1)
        state[15] = bytes_to_word_le(nonce12, 5)
        state[16] = bytes_to_word_le(nonce12, 9)

        local working = {}
        for i = 1, 16 do working[i] = state[i] end

        for _ = 1, 10 do
            quarter_round(working, 1, 5, 9, 13)
            quarter_round(working, 2, 6, 10, 14)
            quarter_round(working, 3, 7, 11, 15)
            quarter_round(working, 4, 8, 12, 16)
            quarter_round(working, 1, 6, 11, 16)
            quarter_round(working, 2, 7, 12, 13)
            quarter_round(working, 3, 8, 9, 14)
            quarter_round(working, 4, 5, 10, 15)
        end

        local out = {}
        for i = 1, 16 do
            local w = to_u32(working[i] + state[i])
            out[#out + 1] = word_to_bytes_le(w)
        end

        return table.concat(out)
    end

    local function xor_strings(a, b)
        local res = {}
        local n = math.min(#a, #b)
        for i = 1, n do
            res[i] = string.char(bit32.bxor(string.byte(a, i), string.byte(b, i)))
        end
        return table.concat(res)
    end

    local function derive_key(secret)
        local _, bin = sha.sha256(secret)
        return bin
    end

    local function operate(message, secret, nonce)
        if not message or not secret or not nonce then return nil end
        if #nonce ~= 12 then error("nonce must be 12 bytes") end

        local key = derive_key(secret)
        local out = {}
        local counter = 0
        local pos = 1

        while pos <= #message do
            local keystream = chacha20_block(key, counter, nonce)
            local block = message:sub(pos, pos + 63)
            local x = xor_strings(block, keystream)
            out[#out + 1] = x
            pos = pos + #block
            counter = (counter + 1) % 2^32
        end

        return table.concat(out)
    end

    function chacha.encrypt(message, secret, nonce)
        return operate(message, secret, nonce)
    end

    function chacha.decrypt(message, secret, nonce)
        return operate(message, secret, nonce)
    end

    function chacha.generateNonce()
        local t = {}
        for i = 1, 12 do t[i] = string.char(math.random(0,255)) end
        return table.concat(t)
    end

    return chacha
end





function bignumlib()
    local B = {}
    local mt = { __index = B }
    local BASE = 256

    local bit = bit32 or bit
    B.yield_function = _CC_DEFAULT_SETTINGS and B.yield_function or function(x) end

    local function zero_digits()
        return {0}
    end

    local function normalize(digits)
        local n = #digits
        while n > 1 and digits[n] == 0 do
            digits[n] = nil
            n = n - 1
        end
        return digits
    end

    local function is_zero(digits)
        return #digits == 1 and digits[1] == 0
    end

    local function compare_abs(a_digits, b_digits)
        if #a_digits > #b_digits then return 1 end
        if #a_digits < #b_digits then return -1 end
        for i = #a_digits, 1, -1 do
            if (a_digits[i] or 0) > (b_digits[i] or 0) then return 1 end
            if (a_digits[i] or 0) < (b_digits[i] or 0) then return -1 end
        end
        return 0
    end

    local function add_abs(a_digits, b_digits)
        local carry = 0
        local result = {}
        local maxLen = math.max(#a_digits, #b_digits)
        for i = 1, maxLen do
            local sum = (a_digits[i] or 0) + (b_digits[i] or 0) + carry
            result[i] = sum % BASE
            carry = math.floor(sum / BASE)
        end
        if carry > 0 then
            result[maxLen + 1] = carry
        end
        return result
    end

    local function sub_abs(a_digits, b_digits)
        local borrow = 0
        local result = {}
        local maxLen = #a_digits
        for i = 1, maxLen do
            local diff = (a_digits[i] or 0) - (b_digits[i] or 0) - borrow
            if diff < 0 then
                diff = diff + BASE
                borrow = 1
            else
                borrow = 0
            end
            result[i] = diff
        end
        return normalize(result)
    end

    local function mul_abs(a_digits, b_digits)
        if is_zero(a_digits) or is_zero(b_digits) then return zero_digits() end
        
        local result = {}
        for i = 1, #a_digits do
            local carry = 0
            for j = 1, #b_digits do
                local k = i + j - 1
                local prod = (a_digits[i] * b_digits[j]) + (result[k] or 0) + carry
                result[k] = prod % BASE
                carry = math.floor(prod / BASE)
            end
            result[i + #b_digits] = carry
        end
        return normalize(result)
    end

    local function lshift_bytes(digits, n)
        if n <= 0 or is_zero(digits) then return digits end
        local result = {}
        for i = 1, n do
            result[i] = 0
        end
        for i = 1, #digits do
            result[i + n] = digits[i]
        end
        return normalize(result)
    end


    local function mul_by_small(digits, n)
        local carry = 0
        local result = {}
        for i = 1, #digits do
            local prod = (digits[i] * n) + carry
            result[i] = prod % BASE
            carry = math.floor(prod / BASE)
        end
        while carry > 0 do
            table.insert(result, carry % BASE)
            carry = math.floor(carry / BASE)
        end
        return result
    end

    local function add_small(digits, n)
        local result = {}
        local sum = digits[1] + n
        result[1] = sum % BASE
        local carry = math.floor(sum / BASE)

        local i = 2
        while i <= #digits or carry > 0 do
            sum = (digits[i] or 0) + carry
            result[i] = sum % BASE
            carry = math.floor(sum / BASE)
            i = i + 1
        end
        return result
    end

    local function divmod_by_small(digits, n)
        local remainder = 0
        local quotient = {}

        for i = #digits, 1, -1 do
            local value = digits[i] + remainder * BASE
            local q = math.floor(value / n)
            quotient[i] = q
            remainder = value % n
        end

        return normalize(quotient), remainder
    end

    local function divmod_abs(a_digits, b_digits)
        if is_zero(b_digits) then error("Division by zero", 2) end
        if compare_abs(a_digits, b_digits) < 0 then
            return zero_digits(), normalize({table.unpack(a_digits)})
        end

        local n, m = #a_digits, #b_digits
        local quotient = {}
        local remainder = {}

        for i = 1, n do remainder[i] = a_digits[i] end

        local norm = math.floor(BASE / (b_digits[m] + 1))
        if norm > 1 then
            remainder = mul_by_small(remainder, norm)
            b_digits = mul_by_small(b_digits, norm)
        end

        n = #remainder
        m = #b_digits

        for i = n - m, 0, -1 do
            local r_hi = remainder[i + m + 1] or 0
            local r_lo = remainder[i + m] or 0
            local num = r_hi * BASE + r_lo
            local den = b_digits[m]
            local q_hat = math.floor(num / den)

            if q_hat >= BASE then q_hat = BASE - 1 end

            local prod = mul_by_small(b_digits, q_hat)
            prod = lshift_bytes(prod, i)

            while q_hat > 0 and compare_abs(remainder, prod) < 0 do
                q_hat = q_hat - 1
                prod = mul_by_small(b_digits, q_hat)
                prod = lshift_bytes(prod, i)
            end

            remainder = sub_abs(remainder, prod)
            quotient[i + 1] = q_hat
        end

        if norm > 1 then
            remainder, _ = divmod_by_small(remainder, norm)
        end

        return normalize(quotient), normalize(remainder)
    end

    local function fromString(str)
        local digits = zero_digits()
        for i = 1, #str do
            local digit_val = str:byte(i) - 48 -- '0' es 48
            if digit_val < 0 or digit_val > 9 then
                error("Invalid number string: " .. str, 2)
            end
            digits = mul_by_small(digits, 10)
            digits = add_small(digits, digit_val)
        end
        return digits
    end

    local function toString(digits, sign)
        if is_zero(digits) then return "0" end
        
        local s = {}
        local temp_digits = digits
        
        while not is_zero(temp_digits) do
            local remainder
            temp_digits, remainder = divmod_by_small(temp_digits, 10)
            table.insert(s, 1, string.char(remainder + 48)) -- '0' es 48
        end
        
        local prefix = (sign < 0) and "-" or ""
        return prefix .. table.concat(s)
    end

    function B.new(n)
        if type(n) == "table" and getmetatable(n) == mt then
            return n
        end

        local obj = {
            sign = 1,
            digits = zero_digits()
        }
        setmetatable(obj, mt)

        local n_type = type(n)
        if n_type == "string" then
            if n:sub(1,1) == "-" then
                obj.sign = -1
                n = n:sub(2)
            end
            obj.digits = fromString(n)
            if is_zero(obj.digits) then obj.sign = 1 end
        elseif n_type == "number" then
            if n < 0 then
                obj.sign = -1
                n = -n
            end
            local d = {}
            local i = 1
            while n > 0 do
                d[i] = n % BASE
                n = math.floor(n / BASE)
                i = i + 1
            end
            obj.digits = #d > 0 and d or zero_digits()
        else
            error("Cannot create bignum from type: " .. n_type, 2)
        end

        return obj
    end

    function B.fromBinary(binaryString)
        local obj = {
            sign = 1,
            digits = {0}
        }
        setmetatable(obj, mt)

        local temp_digits = {0}

        for i = 1, #binaryString do
            local bit_val = binaryString:byte(i) - 48

            temp_digits = mul_by_small(temp_digits, 2)

            if bit_val == 1 then
                temp_digits = add_small(temp_digits, 1)
            elseif bit_val ~= 0 then
                error("Invalid binary string: " .. binaryString, 2)
            end
        end

        obj.digits = temp_digits
        if is_zero(obj.digits) then obj.sign = 1 end
        return obj
    end

    function B.fromBytes(str)
        local obj = { sign = 1, digits = {} }
        setmetatable(obj, mt)
        if str == nil or #str == 0 then
            obj.digits = zero_digits()
            return obj
        end

        for i = 1, #str do
            obj.digits[i] = str:byte(i)
        end

        obj.digits = normalize(obj.digits)
        return obj
    end

    function B:toBytes()
        if is_zero(self.digits) then return "" end

        local chars = {}
        for i = 1, #self.digits do
            chars[i] = string.char(self.digits[i])
        end
        return table.concat(chars)
    end

    function B:toString()
        return toString(self.digits, self.sign)
    end

    function B:clone()
        local c = { sign = self.sign, digits = {} }
        for i = 1, #self.digits do
            c.digits[i] = self.digits[i]
        end
        setmetatable(c, mt)
        return c
    end

    function B:raw_negate()
        local c = self:clone()
        if not is_zero(c.digits) then
            c.sign = -c.sign
        end
        return c
    end

    function B:raw_abs()
        local c = self:clone()
        c.sign = 1
        return c
    end

    function B:bitLength()
        if is_zero(self.digits) then return 0 end

        local last_digit = self.digits[#self.digits]
        local bits_in_last = 0

        while last_digit > 0 do
            last_digit = math.floor(last_digit / 2)
            bits_in_last = bits_in_last + 1
        end

        return (#self.digits - 1) * 8 + bits_in_last
    end

    function B:add(other)
        local a, b = self, B.new(other)
        local result = { sign = 1, digits = zero_digits() }
        setmetatable(result, mt)

        if a.sign == b.sign then
            result.digits = add_abs(a.digits, b.digits)
            result.sign = a.sign
        else
            local cmp = compare_abs(a.digits, b.digits)
            if cmp >= 0 then
                result.digits = sub_abs(a.digits, b.digits)
                result.sign = a.sign
            else
                result.digits = sub_abs(b.digits, a.digits)
                result.sign = b.sign
            end
        end

        if is_zero(result.digits) then result.sign = 1 end
        return result
    end

    function B:sub(other)
        local b_neg = B.new(other):raw_negate()
        return self:add(b_neg)
    end

    function B:mul(other)
        local a, b = self, B.new(other)
        local result = { sign = 1, digits = zero_digits() }
        setmetatable(result, mt)

        result.digits = mul_abs(a.digits, b.digits)
        result.sign = a.sign * b.sign

        if is_zero(result.digits) then result.sign = 1 end
        return result
    end

    function B:divmod(other)
        local a, b = self, B.new(other)
        local q = { sign = 1, digits = zero_digits() }
        local r = { sign = 1, digits = zero_digits() }
        setmetatable(q, mt); setmetatable(r, mt)

        q.digits, r.digits = divmod_abs(a.digits, b.digits)
        q.sign = a.sign * b.sign
        r.sign = a.sign

        if is_zero(q.digits) then q.sign = 1 end
        if is_zero(r.digits) then r.sign = 1 end
        return q, r
    end

    function B:div(other)
        local q, r = self:divmod(B.new(other))
        return q
    end

    function B:mod(other)
        local b_obj = B.new(other)
        local _, r = self:divmod(b_obj)

        if r.sign < 0 then
            r = r + b_obj
        end

        return r
    end

    function B:pow(exp)
        local base = self:clone()
        local exp_obj = B.new(exp)
        local result = B.new(1)
        
        if exp_obj.sign < 0 then
            if self:toString() == "1" then return B.new(1) end
            if self:toString() == "-1" then return exp_obj:mod(2):toString() == "0" and B.new(1) or B.new(-1) end
            return B.new(0)
        end
        
        local ZERO = B.new(0)
        local ONE = B.new(1)
        local TWO = B.new(2)

        while exp_obj > ZERO do
            if (exp_obj % TWO) == ONE then
                result = result * base
            end
            exp_obj = exp_obj / TWO
            base = base * base
        end
        return result
    end

    function B:sqrt()
        local ZERO = B.new(0)
        local ONE = B.new(1)
        local TWO = B.new(2)
        local n = self

        if n < ZERO then error("Square root of negative number", 2) end
        if n == ZERO then return ZERO end

        local num_bits = n:bitLength()
        local x = ONE:lshift(math.ceil(num_bits / 2))

        local prev_x
        local iterations = 0

        repeat
            prev_x = x
            x = (x + (n / x)) / TWO
            iterations = iterations + 1
            B.yield_function(0)
        until x >= prev_x
        return prev_x
    end

    function B:modExp(exp, mod)
        local base = self:clone()
        local exp_obj = B.new(exp)
        local mod_obj = B.new(mod)

        local result = B.new(1)
        base = base % mod_obj

        local ZERO = B.new(0)
        local ONE = B.new(1)
        local TWO = B.new(2)

        while exp_obj > ZERO do
            B.yield_function(0)

            if (exp_obj % TWO) == ONE then
                result = (result * base) % mod_obj
            end
            exp_obj = exp_obj / TWO
            base = (base * base) % mod_obj
        end

        if result.sign < 0 then
            result = result + mod_obj
        end
        return result
    end

    function B:band(other)
        local a, b = self.digits, B.new(other).digits
        local result = {}
        local maxLen = math.max(#a, #b)
        for i = 1, maxLen do
            result[i] = bit.band(a[i] or 0, b[i] or 0)
        end
        local obj = { sign = 1, digits = normalize(result) }
        setmetatable(obj, mt)
        return obj
    end

    function B:bor(other)
        local a, b = self.digits, B.new(other).digits
        local result = {}
        local maxLen = math.max(#a, #b)
        for i = 1, maxLen do
            result[i] = bit.bor(a[i] or 0, b[i] or 0)
        end
        local obj = { sign = 1, digits = normalize(result) }
        setmetatable(obj, mt)
        return obj
    end

    function B:bxor(other)
        local a, b = self.digits, B.new(other).digits
        local result = {}
        local maxLen = math.max(#a, #b)
        for i = 1, maxLen do
            result[i] = bit.bxor(a[i] or 0, b[i] or 0)
        end
        local obj = { sign = 1, digits = normalize(result) }
        setmetatable(obj, mt)
        return obj
    end

    function B:rshift(n)
        local n_bytes = math.floor(n / 8)
        local n_bits = n % 8

        local digits = self.digits
        local result = {}

        if n_bytes > 0 then
            for i = 1, #digits - n_bytes do
                result[i] = digits[i + n_bytes]
            end
            if #result == 0 then return B.new(0) end
        else
            result = self.digits
        end

        if n_bits > 0 then
            local rmask = bit.blshift(1, n_bits) - 1
            local lmask = BASE - 1 - rmask

            local new_digits = {}
            for i = 1, #result do
                local low = bit.band(result[i], rmask)
                local high = bit.brshift(bit.band(result[i], lmask), n_bits)

                new_digits[i] = (new_digits[i] or 0) + high
                if i > 1 then
                    new_digits[i-1] = new_digits[i-1] + bit.blshift(low, 8 - n_bits)
                end
            end
            result = new_digits
        end

        local obj = { sign = 1, digits = normalize(result) }
        setmetatable(obj, mt)
        return obj
    end

    function B:lshift(n)
        local n_bytes = math.floor(n / 8)
        local n_bits = n % 8

        local digits = self.digits
        local result = {}

        if n_bytes > 0 then
            result = lshift_bytes(digits, n_bytes)
        else
            result = self.digits
        end

        if n_bits > 0 then
            local rmask = bit.blshift(1, 8 - n_bits) - 1
            local lmask = BASE - 1 - rmask

            local carry = 0
            local new_digits = {}
            for i = 1, #result do
                local low = bit.blshift(bit.band(result[i], rmask), n_bits)
                local high = bit.brshift(bit.band(result[i], lmask), 8 - n_bits)

                new_digits[i] = low + carry
                carry = high
            end
            if carry > 0 then
                table.insert(new_digits, carry)
            end
            result = new_digits
        end

        local obj = { sign = 1, digits = normalize(result) }
        setmetatable(obj, mt)
        return obj
    end

    mt.__add = function(a, b) return B.new(a):add(B.new(b)) end
    mt.__sub = function(a, b) return B.new(a):sub(B.new(b)) end
    mt.__mul = function(a, b) return B.new(a):mul(B.new(b)) end
    mt.__div = function(a, b) return B.new(a):div(B.new(b)) end
    mt.__mod = function(a, b) return B.new(a):mod(B.new(b)) end
    mt.__pow = function(a, b) return B.new(a):pow(B.new(b)) end
    mt.__unm = function(a) return B.new(a):raw_negate() end
    mt.__tostring = function(a) return a:toString() end

    mt.__eq = function(a, b)
        local a_obj, b_obj = B.new(a), B.new(b)
        if a_obj.sign ~= b_obj.sign then return false end
        return compare_abs(a_obj.digits, b_obj.digits) == 0
    end

    mt.__lt = function(a, b)
        local a_obj, b_obj = B.new(a), B.new(b)
        if a_obj.sign ~= b_obj.sign then
            return a_obj.sign < b_obj.sign
        end
        if a_obj.sign > 0 then
            return compare_abs(a_obj.digits, b_obj.digits) < 0
        else
            return compare_abs(a_obj.digits, b_obj.digits) > 0
        end
    end

    mt.__le = function(a, b)
        local a_obj, b_obj = B.new(a), B.new(b)
        if a_obj.sign ~= b_obj.sign then
            return a_obj.sign < b_obj.sign
        end
        if a_obj.sign > 0 then
            return compare_abs(a_obj.digits, b_obj.digits) <= 0
        else
            return compare_abs(a_obj.digits, b_obj.digits) >= 0
        end
    end

    return function(n)
        return B.new(n)
    end
end


local bignum = bignumlib()
local chacha = chachalib()

function rsalib()

    local rsa = {}

    local ZERO   = bignum("0")
    local ONE    = bignum("1")
    local TWO    = bignum("2")
    local THREE  = bignum("3")
    local FIVE   = bignum("5")
    local SEVEN  = bignum("7")
    local ELEVEN = bignum("11")

    local MILLER_RABIN_BASES = {TWO, THREE, FIVE, SEVEN, ELEVEN}

    math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1, 5)))

    local _small_primes_cache = nil

    local function generate_small_primes(limit)
        limit = limit or 2000

        local sieve_limit = 17400

        local sieve = {}
        for i = 2, sieve_limit do
            sieve[i] = true
        end

        for p = 2, math.sqrt(sieve_limit) do
            if sieve[p] then
                os.sleep(0)

                for i = p * p, sieve_limit, p do
                    sieve[i] = false
                end
            end
        end

        local native_primes = {}
        for p = 2, sieve_limit do
            if sieve[p] then
                table.insert(native_primes, p)
                if #native_primes >= limit then
                    break
                end
            end
        end

        local bignum_primes = {}
        for _, p_num in ipairs(native_primes) do
            table.insert(bignum_primes, bignum(tostring(p_num)))
        end

        return bignum_primes
    end

    local function get_small_primes()
        if not _small_primes_cache then
            _small_primes_cache = generate_small_primes(2000)
        end
        return _small_primes_cache
    end

    local function is_sieved(n, sieve)
        for _, p in ipairs(sieve) do
            if n % p == ZERO then
                return true
            end
        end
        return false
    end

    local function generate_random_bits(n)
        if n < 2 then error("It needs at least 2 bits", 2) end
        local bits = {}

        bits[1] = 1
        bits[n] = 1

        for i = 2, n - 1 do
            bits[i] = math.random(0, 1)
        end

        return ZERO.fromBinary(table.concat(bits))
    end

    local function miller_rabin(n)
        if n == TWO or n == THREE or n == FIVE or n == SEVEN or n == ELEVEN then return true end
        if n < TWO or n % TWO == ZERO then return false end

        local n_minus_one = n - ONE

        local s = ZERO
        local d = n_minus_one
        while d % TWO == ZERO do
            d = d / TWO
            s = s + ONE
        end

        for _, a in ipairs(MILLER_RABIN_BASES) do
            if a < n_minus_one then
                local x = a:modExp(d, n)

                if x ~= ONE and x ~= n_minus_one then
                    local is_composite = true
                    local s_minus_one = s - ONE
                    local i = ZERO

                    while i < s_minus_one do
                        x = x:modExp(TWO, n)
                        if x == ONE then
                            return false
                        end
                        if x == n_minus_one then
                            is_composite = false
                            break
                        end
                        i = i + ONE
                    end

                    if is_composite then
                        return false
                    end
                end
            end
        end

        return true
    end

    local function generate_prime(bits)
        local sieve = get_small_primes()
        local results = {}

        local function find_single_prime_task(pos)
            local candidate = generate_random_bits(bits)
            if candidate % TWO == ZERO then
                candidate = candidate + ONE
            end

            local bit_length = candidate:bitLength()

            while true do
                os.sleep(0)

                if not is_sieved(candidate, sieve) then

                    if miller_rabin(candidate) then
                        results[pos] = candidate
                        return
                    end

                end

                candidate = candidate + TWO

                if candidate:bitLength() > bit_length then
                    candidate = generate_random_bits(bits)
                    if candidate % TWO == ZERO then
                        candidate = candidate + ONE
                    end
                end
            end
        end

        parallel.waitForAll(function ()
            find_single_prime_task(1) end, function ()
            find_single_prime_task(2) end)
            
        local p = results[1]
        local q = results[2]

        while p == q do
            q = find_single_prime_task()
        end

        return p, q
    end

    local function gcd(x, y)
        while y ~= ZERO do
            x, y = y, x % y
        end
        return x
    end

    local function gcd_extended(a, b)
        if b == ZERO then
            return a, ONE, ZERO
        end
        local g, x1, y1 = gcd_extended(b, a % b)
        local x = y1
        local y = x1 - (a / b) * y1

        return g, x, y
    end

    local function modular_inverse(a, m)
        local g, x, _ = gcd_extended(a, m)
        if g ~= ONE then
            return nil
        end

        if x < ZERO then
            x = x + m
        end

        return x % m
    end

    local function generate_public_key(phi_N)
        local e = bignum("65537")
        if gcd(phi_N, e) == ONE then
            return e
        end
        error("Failed to find public exponent")
    end

    function rsa.generate_keys(bits)
        get_small_primes()
        local p, q = generate_prime(bits)

        local n = p * q
        local phi_N = (p - ONE) * (q - ONE)

        local e = generate_public_key(phi_N)
        if not e then
            printError("Failed to create public key (e)")
            error("Key generation failed")
        end

        local d = modular_inverse(e, phi_N)
        if not d then
            printError("Failed to create private key (d)")
            error("Key generation failed")
        end

        local dP = d % (p - ONE)
        local dQ = d % (q - ONE)
        local qInv = modular_inverse(q, p)

        if not qInv then
            printError("Failed to calculate qInv for CRT")
            error("Key generation failed")
        end

        return {e, n}, {d, n, p, q, dP, dQ, qInv}
    end

    local function encrypt_internal(message, key)
        if #key < 2 then
            printError("Invalid parameters: message must be a number/string/bignum and key must contain 2 elements.")
            error("Invalid parameters")
        end

        local msg_num = bignum(message)
        local n = key[2]

        if msg_num < ZERO or msg_num > n then
            printError("Message too large to encrypt: must be between 0 and n.")
            error("Message overflow")
        end

        return msg_num:modExp(key[1], n)
    end

    function rsa.encrypt(message, public_key)
        local msg_num

        if type(message) == "string" then
            msg_num = ZERO.fromBytes(message)
        elseif type(message) == "table" or type(message) == "number" then
            msg_num = bignum(message)
        else
            printError("Tipo de mensaje no válido para cifrar.")
            error("Tipo de mensaje no válido")
        end

        return encrypt_internal(msg_num, public_key)
    end

    function rsa.decrypt(message, private_key)
        local c = bignum(message)

        local d = private_key[1]
        local n = private_key[2]

        if not private_key[7] then
            printError("WARNING: Private key does not contain CRT values. Using slow decryption.")
            local decrypted_num = c:modExp(d, n)

            return decrypted_num:toBytes()
        end

        local p = private_key[3]
        local q = private_key[4]
        local dP = private_key[5]
        local dQ = private_key[6]
        local qInv = private_key[7]

        local m1 = c:modExp(dP, p)

        local m2 = c:modExp(dQ, q)

        local h = (qInv * (m1 - m2)) % p
        if h < ZERO then
            h = h + p
        end

        local m_decrypted = m2 + h * q

        return m_decrypted:toBytes()
    end

    return rsa
end

local rsa = rsalib()

function secp256k1lib()
    local sha = require("..iDar.CryptoLib.src.sha")
    local bignum = require("..iDar.Bignum.src.bigNum")

    local ecc = {}

    local ZERO = bignum("0")
    local ONE = bignum("1")
    local TWO = bignum("2")
    local THREE = bignum("3")
    local FOUR = bignum("4")
    local SEVEN = bignum("7")
    local EIGHT = bignum("8")
    local P = bignum("115792089237316195423570985008687907853269984665640564039457584007908834671663")
    local G = {x = bignum("55066263022277343669578718895168534326250603453777594175500187360389116729240"), y = bignum("32670510020758816978083085130507043184471273380659243275938904335757337482424")}
    local N = bignum("115792089237316195423570985008687907852837564279074904382605163141518161494337")

    local function random_big_int(nbytes)
        local seed = os.epoch("utc") + os.getComputerID()
        math.randomseed(seed)
        local bytes = {}
        for i = 1, nbytes do
            bytes[i] = string.char(math.random(0, 255))
        end
        return ZERO.fromBytes(table.concat(bytes))
    end

    local function hash_message(message)
        local _, bin_digest = sha.sha256(message)
        local z = ZERO.fromBytes(bin_digest)
        return z % N
    end

    local function generate_k(priv, z)
        local key = priv:toBytes()
        local h1 = z:toBytes()

        local K = string.rep("\x00", 32)
        local V = string.rep("\x01", 32)

        K = sha.hmac_sha256(K, V .. "\x00" .. key .. h1, true)
        V = sha.hmac_sha256(K, V, true)

        while true do
            V = sha.hmac_sha256(K, V, true)
            local k = ZERO.fromBytes(V)
            if k > ZERO and k < N then
                return k
            end
            K = sha.hmac_sha256(K, V .. "\x00", true)
            V = sha.hmac_sha256(K, V, true)
        end
    end

    local function modular_inverse(a, m)
        local x, y, u, v = ZERO, ONE, ONE, ZERO
        local b = m
        a = a % m
        while a ~= ZERO do
            local q = b / a
            local r = b % a
            local m_ = x - u * q
            local n = y - v * q
            b, a, x, y, u, v = a, r, u, v, m_, n
        end
        if b ~= ONE then return nil end
        return x % m
    end

    local function to_affine(p)
        if p.z == ONE or not p.z then return {x = p.x, y = p.y} end

        local zinv = modular_inverse(p.z, P)
        local zinv2 = (zinv * zinv) % P
        local zinv3 = (zinv2 * zinv) % P

        os.sleep(0)
        return {
            x = (p.x * zinv2) % P,
            y = (p.y * zinv3) % P
        }
    end

    local function is_on_curve(pt)
        if not pt then return false end
        if not pt.z or pt.z == ONE then
            local lhs = (pt.y * pt.y) % P
            local rhs = (pt.x * pt.x * pt.x + SEVEN) % P
            return lhs == rhs
        else
            local a = to_affine(pt)
            return is_on_curve(a)
        end
    end

    local function point_double(p)
        if p.y == ZERO then return nil end

        local y2 = (p.y * p.y) % P
        local s = (FOUR * p.x * y2) % P
        local m = (THREE * p.x * p.x) % P

        local nx = (m * m - TWO * s) % P
        local ny = (m * (s - nx) - EIGHT * y2 * y2) % P
        local nz = (TWO * p.y * p.z) % P

        return {x = nx, y = ny, z = nz}
    end

    local function point_add(p, q)
        if not p then return q end
        if not q then return p end

        if not q.z then q = {x = q.x, y = q.y, z = ONE} end
        if not p.z then p = {x = p.x, y = p.y, z = ONE} end

        local z1z1 = (p.z * p.z) % P
        local z2z2 = (q.z * q.z) % P
        local u1 = (p.x * z2z2) % P
        local u2 = (q.x * z1z1) % P
        local s1 = (p.y * q.z * z2z2) % P
        local s2 = (q.y * p.z * z1z1) % P

        if u1 == u2 then
            if s1 == s2 then
                return point_double(p)
            else
                return nil
            end
        end

        local h = (u2 - u1) % P
        local i = (FOUR * h * h) % P
        local j = (h * i) % P
        local r = (TWO * (s2 - s1)) % P
        local v = (u1 * i) % P

        local nx = (r * r - j - TWO * v) % P
        local ny = (r * (v - nx) - TWO * s1 * j) % P
        local nz = ((p.z + q.z) * (p.z + q.z) - z1z1 - z2z2) % P
        nz = (nz * h) % P

        return {x = nx, y = ny, z = nz}
    end

    local function scalar_multiply(k, p)
        local precomputed = { nil }
        precomputed[1] = p
        for i = 2, 16 do
            precomputed[i] = point_add(precomputed[i-1], p)
        end

        local R = nil
        for i = 63, 0, -1 do
            if R then
                R = point_double(R)
                R = point_double(R)
                R = point_double(R)
                R = point_double(R)
            end

            local window = k:rshift(i*4):band(15)
            if window ~= ZERO then
                R = point_add(R, precomputed[window.digits[1]])
            end
        end
        return R
    end

    function ecc.generatePrivateKey()
        local k = random_big_int(32)
        return k % (N - ONE) + ONE
    end

    function ecc.getPublicKey(priv_key)
        local Pj = scalar_multiply(priv_key, G)
        return to_affine(Pj)
    end

    function ecc.getSharedSecret(my_priv_key, their_pub_key)
        if not is_on_curve(their_pub_key) then return nil end
        local shared_point = scalar_multiply(my_priv_key, their_pub_key)
        if not shared_point then return nil end
        local affine = to_affine(shared_point)
        return affine.x
    end

    function ecc.sign(priv_key, message)
        local z = hash_message(message)

        local k = generate_k(priv_key, z)
        local R_proj = scalar_multiply(k, G)
        R_affine = to_affine(R_proj)
        local r = R_affine.x % N
        local k_inv = modular_inverse(k, N)
        local term1 = (r * priv_key) % N
        local term2 = (z + term1) % N
        local s = (k_inv * term2) % N

        return {r = r, s = s}
    end

    function ecc.verify(pub_key, message, sign)
        if not is_on_curve(pub_key) then
            return {result = false, message = "Invalid public key"}
        end
        local z = hash_message(message)

        if sign.r < ONE or sign.r > N - ONE or sign.s < ONE or sign.s > N - ONE then
            return {result = false, message = "Invalid r or s range"}
        end

        local w = modular_inverse(sign.s, N)
        if not w then return {result = false, message = "Cannot calculate s inverse"} end
        local u1 = (z * w) % N
        local u2 = (sign.r * w) % N
        local P1 = scalar_multiply(u1, G)
        os.sleep(0)
        local P_pub_proj = {x = pub_key.x, y = pub_key.y, z = ONE}
        local P2 = scalar_multiply(u2, P_pub_proj)
        os.sleep(0)
        local R_prime_proj = point_add(P1, P2)

        if not R_prime_proj then
            return {result = false, message = "Point addition resulted in infinity"}
        end

        local R_prime_affine = to_affine(R_prime_proj)

        local r_prime = R_prime_affine.x % N
        print("R de verifiacion: ", r_prime)

        return {result = sign.r == r_prime, message = "Signature verification result"}
    end

    return ecc
end

local secp256k1 = secp256k1lib()
return {
    ["rsa"] = rsa,
    ["ecc"] = secp256k1,
    ["bignum"] = bignum,
    ["chacha"] = chacha,
    ["aes"] = aes,
    ["sha"] = sha
}