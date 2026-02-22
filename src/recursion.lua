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
-- Note: Key/String has limit of 65535 bytes, exceed amount will result in **UNDEFINED BEHAVIOUR**
-- returning nil for baddata
function recursion.getBufferFromRecursiveTable(tab: {any}): buffer?
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
                    cursor = after_key_cursor

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
function recursion.getTableFromRecursiveBuffer(buf: buffer): {any}?
    
end

return recursion
