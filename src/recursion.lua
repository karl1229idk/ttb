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

---
-- Utilities
---

function newBufWithNewPage(buf, target_size, count)
    local new_buf = buffer.create(target_size)
    buffer.copy(new_buf, 0, buf, 0, count)

    return new_buf
end

---
-- Root
---

local recursion = {}

-- Accept recursive table to buffer. ONLY use the function in this module to decode
-- Note: that this function is very slow and intended to debug/development, TTBW doesn't know your type until runtime
-- returning nil for baddata
function recursion.getBufferFromRecursiveTable(table: {any}): buffer?
    local buffer_size = 8192
    local cursor = 0
    local starter_buffer = buffer.create(buffer_size)

    local function recursive_write(table)
        local after_header_buffer_pos = cursor + 1
        if after_header_buffer_pos > buffer_size then
            buffer_size += 4096

            starter_buffer = newBufWithNewPage(starter_buffer, buffer_size, cursor)
        end

        buffer.writeu8(starter_buffer, cursor, 0xAA)
        cursor = after_header_buffer_pos

        for key, value in pairs(table) do
            local typ = typeof(value)
            local tag = ttb.tag_lookup[typ]
            if not tag then
                if typ == "table" then
                    recursive_write(value)
                    continue
                end

                warn("Unsupported type of \"" .. typ .. "\"")
                return
            end

            local branch = ttb.master_table[tag]

            local delta_size = branch.size or branch.measure(value)
            local after_tag_cursor = cursor + 1
            local used_size = after_tag_cursor + delta_size
            if buffer_size < used_size then
                buffer_size += 4096
                
                starter_buffer = newBufWithNewPage(starter_buffer, buffer_size, cursor)
            end

            buffer.writeu8(starter_buffer, cursor, tag)
            branch.write(starter_buffer, after_tag_cursor, value)
            cursor = used_size
        end
        
        local after_finisher_buffer_pos = cursor + 1
        if after_finisher_buffer_pos > buffer_size then
            buffer_size += 4096

            starter_buffer = newBufWithNewPage(starter_buffer, buffer_size, cursor)
        end

        buffer.writeu8(starter_buffer, cursor, 0xAB)
        cursor = after_finisher_buffer_pos
    end

    recursive_write(table)

    local final_buffer = buffer.create(cursor)
    buffer.copy(final_buffer, 0, starter_buffer, 0, cursor)

    return final_buffer
end

-- Change buffer generated from getBufferFromRecursiveTable() and change it back to table
function recursion.getRecursiveTableFromBuffer(buf: buffer): {any}?
    local buffer_size = buffer.len(buf)
    local cursor = 0

    local tabl = {}

    while cursor < buffer_size do
        cursor += 1

    end

    return tabl
end

return recursion
