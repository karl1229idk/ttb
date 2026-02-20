-- SPDX-FileCopyrightText: 2026 karl_dev1229 <karl1229idk@gmail.com>
--
-- SPDX-License-Identifier: MPL-2.0
-- Full license text available at: https://www.mozilla.com/MPL/2.0

---
-- @title: ttbw
-- @description: A simple wrapper to TTB, purposed to let the library be general-use-ready
-- @version: 1.0.1
-- @author: karl_dev1229
---

--!native
--!optimize 2
--!nocheck

---
-- Import
---

local ttb = require(script.Parent)
local ttb_master = ttb.master_table
local ttb_tag_lookup = ttb.tag_lookup

---
-- Root
---

local ttbw = { ttb = ttb }

function ttbw.safeEncodeArray(array: {any}, typ: string?): buffer?
    if typeof(array) ~= "table" then
        warn("\"array\" arg must be a table")
        return nil
    end
    if #array == 0 then return ttb.getBufferFromArray(array, "number") end

    local target = typ or typeof(array[1])
    local branch = ttb_master[ttb_tag_lookup[target]]
    if not branch then
        warn("Unsupported type of \"" .. target .. "\"")
        return nil
    end

    return ttb.getBufferFromArray(array, target)
end

function ttbw.safeEncodeHashmap(hashmap: {[string]: any}, typ: string?): buffer?
    if typeof(hashmap) ~= "table" then
        warn("\"hashmap\" arg must be a table")
        return nil
    end

    local type_name = typ
    if not type_name then
        local _, first_val = next(hashmap)
        type_name = typeof(first_val)
    end
    local tag = ttb_tag_lookup[type_name]
    if not tag then
        warn("Unsupported type of \"" .. type_name .. "\"")
        return nil
    end

    local branch = ttb_master[tag]
    local branch_size = branch.size

    local pair_count = 0
    local ets_size = 3

    for key, val in pairs(hashmap) do
        if typeof(key) ~= "string" then
            warn("hashmap key must be a string")
            return nil
        end

        if #key > 255 then
            warn("key size cannot exceed 255 bytes")
            return nil
        end

        local val_type_name = typeof(val)
        if val_type_name ~= type_name then
            warn("expected typeof \"" .. type_name .. "\", found \"" .. val_type_name "\"")
            return nil
        end

        pair_count += 1
        ets_size += #key + 1
        if branch_size then
            ets_size += branch_size
        else
            local str_len = #val
            if str_len > 65535 then
                warn("string size cannot exceed 65535 bytes")
                return nil
            end
            ets_size += str_len + 2
        end
    end

    if pair_count > 65535 then
        warn("Hashmap cannot contain more than 65535 pairs")
        return nil
    end

    return ttb.getBufferFromHashmap(hashmap, type_name)
end

-- Reminders:
-- - nil indiciate failed read due to invalid buffer
-- - data can still be exploited, don't trust client
-- - data will be read if possible, check buffer size yourself before decode
function ttbw.safeDecode(buf: buffer?): {any}?
    if typeof(buf) ~= "buffer" then
        warn("Input must be a buffer!")
        return nil
    end

    local buf_size = buffer.len(buf)
    if buf_size < 1 then
        warn("Zero-sized buffer is invalid")
        return nil
    end

    local tag = buffer.readu8(buf, 0)
    local clean_tag = bit32.band(0x7F, tag)

    local branch = ttb_master[clean_tag]
    if not branch then return nil end

    if not clean_tag then
        warn("buffer contain an invalid type tag")
        return nil
    end

    local is_hashmap = bit32.band(0x80, tag) > 0
    if is_hashmap then
        if buf_size < 3 then return nil end

        local result = {}
        local key_count = buffer.readu16(buf, 1)
        local at = 3

        local branch_size = branch.size
        local branch_read = branch.read

        for i = 1, key_count do
            if at >= buf_size then return nil end
            
            local key_len = buffer.readu8(buf, at)
            at += 1

            local future_at = at + key_len
            if future_at > buf_size then return nil end

            local key = buffer.readstring(buf, at, key_len)
            at = future_at

            local val
            if branch_size then
                future_at += branch_size
                if future_at > buf_size then return nil end
                val = branch_read(buf, at)
            else
                -- string logic

                future_at += 2
                if future_at > buf_size then return nil end

                local str_len = buffer.readu16(buf, at)
                at = future_at
                future_at += str_len

                if future_at > buf_size then return nil end
                val = buffer.readstring(buf, at, str_len)
            end
            result[key] = val
            at = future_at
        end

        return result
    end

    return ttb.decode(buf)
end

return ttbw
