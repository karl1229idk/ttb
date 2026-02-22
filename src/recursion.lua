-- SPDX-FileCopyrightText: 2026 karl_dev1229 <karl1229idk@gmail.com>
--
-- SPDX-License-Identifier: MPL-2.0
-- Full license text available at: https://www.mozilla.com/MPL/2.0

---
-- @title: recursion
-- @description: Recursion handling for ttb
-- @version: 1.1.1
-- @author: karl_dev1229
---

--!native
--!optimize 2
--!nocheck

---
-- Import
---

local ttb = require(script.Parent)
local tag_lookup = ttb.tag_lookup
local master_table = ttb.master_table

---
-- Root
---

local recursion = {}

-- Accept recursive table to buffer. ONLY use the function in this module to decode
-- Note: that this function is slow and intended to debug/development, the module doesn't know your type until runtime
-- Note: key/string has limit of 65535 bytes, exceed amount will result in **UNDEFINED BEHAVIOUR**
-- Note: this function mangle number key to string, for example, { [1] = 1 } become { ["1"] = 1 }
-- returning nil for baddata
function recursion.getBufferFromRecursiveTable(tab: {any}): buffer?
    local seen = {}
    local baddata
    local buffer_size = 8192
    local cursor = 0
    local starter_buffer = buffer.create(buffer_size)
    local function realloc(at)
        if at > buffer_size then
            local new_buffer_size = buffer_size + 4096
            local new_buffer = buffer.create(new_buffer_size)

            buffer.copy(new_buffer, 0, starter_buffer, 0, buffer_size)

            buffer_size = new_buffer_size
            starter_buffer = new_buffer
        end
    end

    local function recursiveWrite(tab)
        for key, value in pairs(tab) do
            local typ = typeof(value)
            local tag = tag_lookup[typ]

            local after_tag_cursor = cursor + 1
            local after_key_size_cursor = after_tag_cursor + 2
            local str_key = tostring(key)
            local key_size = #str_key
            local after_key_cursor = after_key_size_cursor + key_size

            realloc(after_key_cursor)

            buffer.writeu8(starter_buffer, cursor, tag or 0)
            buffer.writeu16(starter_buffer, after_tag_cursor, key_size)
            buffer.writestring(starter_buffer, after_key_size_cursor, str_key)

            if not tag then
                if typ == "table" then
                    if seen[value] then
                        warn("No circular reference is allowed")
                        baddata = true
                        return
                    end

                    cursor = after_key_cursor

                    seen[value] = true
                    recursiveWrite(value)
                    if baddata then
                        return
                    end

                    continue
                end

                warn("Unsupported type of \"" .. typ .. "\"")

                baddata = true
                return
            end

            local branch = master_table[tag]

            local delta_value_size = branch.size or branch.measure(value)
            local after_value_cursor = after_key_cursor + delta_value_size

            realloc(after_value_cursor)
            
            branch.write(starter_buffer, after_key_cursor, value)

            cursor = after_value_cursor
        end

        local after_end_tag_cursor = cursor + 1
        realloc(after_end_tag_cursor)

        buffer.writeu8(starter_buffer, cursor, 0xFF)
        cursor = after_end_tag_cursor
    end

    recursiveWrite(tab)
    if baddata then
        return
    end

    local final_buffer = buffer.create(cursor)
    buffer.copy(final_buffer, 0, starter_buffer, 0, cursor)

    return final_buffer
end

-- Accept recursive table to buffer. ONLY use the function in this module to decode
-- returning nil for corrupted buffer
function recursion.safeGetTableFromRecursiveBuffer(buf: buffer, depth_limit: number?): {any}?
    local result_table = {}
    local buffer_size = buffer.len(buf)
    local cursor = 0
    local current_depth = 0

    local function recursiveRead(target_table)
        current_depth += 1
        if depth_limit and current_depth > depth_limit then
            return
        end

        while true do
            local after_tag_cursor = cursor + 1
            if after_tag_cursor > buffer_size then
                return
            end

            local tag = buffer.readu8(buf, cursor)
            if tag == 0xFF then
                cursor += 1
                break
            end

            local after_key_size_cursor = after_tag_cursor + 2
            if after_key_size_cursor > buffer_size then
                return
            end

            local key_size = buffer.readu16(buf, after_tag_cursor)
            local after_key_cursor = after_key_size_cursor + key_size
            if after_key_cursor > buffer_size then
                return
            end

            local key = buffer.readstring(buf, after_key_size_cursor, key_size)
            
            local branch = master_table[tag]
            if not branch then
                if tag == 0 then
                    cursor = after_key_cursor
                    target_table[key] = {}
                    if not recursiveRead(target_table[key]) then
                        return
                    end

                    continue
                end

                return
            end

            local size = branch.size
            if not size then
                local after_string_size_cursor = after_key_cursor + 2
                if after_string_size_cursor > buffer_size then
                    return
                end

                size = buffer.readu16(buf, after_key_cursor) + 2
            end

            local after_value_cursor = after_key_cursor + size
            if after_value_cursor > buffer_size then
                return
            end

            target_table[key] = branch.read(buf, after_key_cursor)
            cursor = after_value_cursor
        end

        return true
    end

    if not recursiveRead(result_table) then
        return
    end

    return result_table
end

-- Accept recursive table to buffer. ONLY use the function in this module to decode
-- Note: this function assume the buffer is not corrupted, but it is faster than safeGetTableFromRecursiveBuffer()
-- returing {any}, or UB, or error, or trash
function recursion.getTableFromRecursiveBuffer(buf: buffer): {any}?
    local result_table = {}
    local cursor = 0

    local function recursiveRead(target_table)
        while true do
            local after_tag_cursor = cursor + 1

            local tag = buffer.readu8(buf, cursor)
            if tag == 0xFF then
                cursor += 1
                break
            end

            local after_key_size_cursor = after_tag_cursor + 2

            local key_size = buffer.readu16(buf, after_tag_cursor)
            local after_key_cursor = after_key_size_cursor + key_size

            local key = buffer.readstring(buf, after_key_size_cursor, key_size)
            
            local branch = master_table[tag]
            if not branch then
                -- assume table
                cursor = after_key_cursor
                target_table[key] = {}
                recursiveRead(target_table[key])

                continue
            end

            local size = branch.size
            if not size then
                size = buffer.readu16(buf, after_key_cursor) + 2
            end

            local after_value_cursor = after_key_cursor + size

            target_table[key] = branch.read(buf, after_key_cursor)
            cursor = after_value_cursor
        end
    end

    recursiveRead(result_table)

    return result_table
end

return recursion
