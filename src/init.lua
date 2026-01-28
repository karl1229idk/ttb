-- SPDX-FileCopyrightText: 2026 karl_dev1229 <karl1229idk@gmail.com>
--
-- SPDX-License-Identifier: MPL-2.0
-- Full license text available at: https://www.mozilla.com/MPL/2.0

---
-- @title: ttb
-- @description: A simple library to transform table and buffer
-- @version: 0.1.0
-- @author: karl_dev1229
---

--!native
--!optimize 2
--!nocheck

local transform_table_buffer = {}

-- Internal tags
local tags = {
    Number = 1,
    String = 2,
    CFrame = 3,
    f32 = 4,
    u8 = 5,
    u16 = 6,
    i32 = 7,
    vector3 = 8,
    vector2 = 9,
    color3 = 10,
    color3f = 11,
    bool = 12
}

-- Internal tag loopup with type name
local tag_lookup = {
    ["number"] = tags.Number,
    ["string"] = tags.String,
    ["CFrame"] = tags.CFrame,
    ["f32"] = tags.f32,
    ["u8"] = tags.u8,
    ["u16"] = tags.u16,
    ["i32"] = tags.i32,
    ["Vector3"] = tags.vector3,
    ["Vector2"] = tags.vector2,
    ["Color3"] = tags.color3,
    ["Color3F"] = tags.color3f,
    ["boolean"] = tags.bool,
    ["f64"] = tags.Number
}

-- Master lookup table for branch
-- You should not use tags / master_table unless you are not using the API
-- Usage: master_table[<tag>]
local master_table = {
    [tags.Number] = {
        size = 8,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writef64(buf, offset, val)
                offset += 8
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = buffer.readf64(buf, at)
                at += 8
            end
        end,

        write = function(buf, offset, val)
            buffer.writef64(buf, offset, val)
        end,
        
        read = function(buf, offset)
            return buffer.readf64(buf, offset)
        end
    },

    [tags.String] = {
        write = function(buf, at, val)
            local len = #val
            buffer.writeu16(buf, at, len)
            buffer.writestring(buf, at + 2, val)
            return 2 + len
        end,

        read = function(buf, at)
            local len = buffer.readu16(buf, at)
            return buffer.readstring(buf, at + 2, len), len + 2
        end,

        measure = function(val)
            return 2 + #val
        end
    },

    [tags.CFrame] = {
        size = 48,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = 
                    val:GetComponents()
                buffer.writef32(buf, offset, x)
                buffer.writef32(buf, offset + 4, y)
                buffer.writef32(buf, offset + 8, z)
                buffer.writef32(buf, offset + 12, r00)
                buffer.writef32(buf, offset + 16, r01)
                buffer.writef32(buf, offset + 20, r02)
                buffer.writef32(buf, offset + 24, r10)
                buffer.writef32(buf, offset + 28, r11)
                buffer.writef32(buf, offset + 32, r12)
                buffer.writef32(buf, offset + 36, r20)
                buffer.writef32(buf, offset + 40, r21)
                buffer.writef32(buf, offset + 44, r22)
                offset += 48
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = CFrame.new(
                    buffer.readf32(buf, at),
                    buffer.readf32(buf, at + 4),
                    buffer.readf32(buf, at + 8),
                    buffer.readf32(buf, at + 12),
                    buffer.readf32(buf, at + 16),
                    buffer.readf32(buf, at + 20),
                    buffer.readf32(buf, at + 24),
                    buffer.readf32(buf, at + 28),
                    buffer.readf32(buf, at + 32),
                    buffer.readf32(buf, at + 36),
                    buffer.readf32(buf, at + 40),
                    buffer.readf32(buf, at + 44)
                )
                at += 48
            end
        end,

        write = function(buf, offset, val)
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = 
                    val:GetComponents()
            buffer.writef32(buf, offset, x)
            buffer.writef32(buf, offset + 4, y)
            buffer.writef32(buf, offset + 8, z)
            buffer.writef32(buf, offset + 12, r00)
            buffer.writef32(buf, offset + 16, r01)
            buffer.writef32(buf, offset + 20, r02)
            buffer.writef32(buf, offset + 24, r10)
            buffer.writef32(buf, offset + 28, r11)
            buffer.writef32(buf, offset + 32, r12)
            buffer.writef32(buf, offset + 36, r20)
            buffer.writef32(buf, offset + 40, r21)
            buffer.writef32(buf, offset + 44, r22)
        end,
        
        read = function(buf, offset)
            return CFrame.new(
                buffer.readf32(buf, offset),
                buffer.readf32(buf, offset + 4),
                buffer.readf32(buf, offset + 8),
                buffer.readf32(buf, offset + 12),
                buffer.readf32(buf, offset + 16),
                buffer.readf32(buf, offset + 20),
                buffer.readf32(buf, offset + 24),
                buffer.readf32(buf, offset + 28),
                buffer.readf32(buf, offset + 32),
                buffer.readf32(buf, offset + 36),
                buffer.readf32(buf, offset + 40),
                buffer.readf32(buf, offset + 44)
            )
        end
    },

    [tags.f32] = {
        size = 4,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writef32(buf, offset, val)
                offset += 4
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = buffer.readf32(buf, at)
                at += 4
            end
        end,

        write = function(buf, offset, val)
            buffer.writef32(buf, offset, val)
        end,
        
        read = function(buf, offset)
            return buffer.readf32(buf, offset)
        end
    },

    [tags.u8] = {
        size = 1,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writeu8(buf, offset, val)
                offset += 1
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = buffer.readu8(buf, at)
                at += 1
            end
        end,

        write = function(buf, offset, val)
            buffer.writeu8(buf, offset, val)
        end,
        
        read = function(buf, offset)
            return buffer.readu8(buf, offset)
        end
    },

    [tags.u16] = {
        size = 2,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writeu16(buf, offset, val)
                offset += 2
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = buffer.readu16(buf, at)
                at += 2
            end
        end,

        write = function(buf, offset, val)
            buffer.writeu16(buf, offset, val)
        end,
        
        read = function(buf, offset)
            return buffer.readu16(buf, offset)
        end
    },

    [tags.i32] = {
        size = 4,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writei32(buf, offset, val)
                offset += 4
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = buffer.readi32(buf, at)
                at += 4
            end
        end,

        write = function(buf, offset, val)
            buffer.writei32(buf, offset, val)
        end,
        
        read = function(buf, offset)
            return buffer.readi32(buf, offset)
        end
    },
    
    [tags.vector3] = {
        size = 12,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writef32(buf, offset, val.X)
                buffer.writef32(buf, offset + 4, val.Y)
                buffer.writef32(buf, offset + 8, val.Z)
                offset += 12
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = Vector3.new(
                    buffer.readf32(buf, at),
                    buffer.readf32(buf, at + 4),
                    buffer.readf32(buf, at + 8)
                )
                at += 12
            end
        end,

        write = function(buf, offset, val)
            buffer.writef32(buf, offset, val.X)
            buffer.writef32(buf, offset + 4, val.Y)
            buffer.writef32(buf, offset + 8, val.Z)
        end,
        
        read = function(buf, offset)
            return Vector3.new(
                buffer.readf32(buf, offset),
                buffer.readf32(buf, offset + 4),
                buffer.readf32(buf, offset + 8)
            )
        end
    },

    [tags.vector2] = {
        size = 8,

        writer = function(buf, t)
            local offset = 1
            
            for i = 1, #t do
                local val = t[i]
                buffer.writef32(buf, offset, val.X)
                buffer.writef32(buf, offset + 4, val.Y)
                offset += 8
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = Vector2.new(
                    buffer.readf32(buf, at),
                    buffer.readf32(buf, at + 4)
                )
                at += 8
            end
        end,

        write = function(buf, offset, val)
            buffer.writef32(buf, offset, val.X)
            buffer.writef32(buf, offset + 4, val.Y)
        end,
        
        read = function(buf, offset)
            return Vector2.new(
                buffer.readf32(buf, offset),
                buffer.readf32(buf, offset + 4)
            )
        end
    },

    [tags.color3] = {
        size = 3,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writeu8(buf, offset, val.R * 255)
                buffer.writeu8(buf, offset + 1, val.G * 255)
                buffer.writeu8(buf, offset + 2, val.B * 255)
                offset += 3
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = Color3.fromRGB(
                    buffer.readu8(buf, at),
                    buffer.readu8(buf, at + 1),
                    buffer.readu8(buf, at + 2)
                )
                at += 3
            end
        end,

        write = function(buf, offset, val)
            buffer.writeu8(buf, offset, val.R * 255)
            buffer.writeu8(buf, offset + 1, val.G * 255)
            buffer.writeu8(buf, offset + 2, val.B * 255)
        end,
        
        read = function(buf, offset)
            return Color3.fromRGB(
                buffer.readu8(buf, offset),
                buffer.readu8(buf, offset + 1),
                buffer.readu8(buf, offset + 2)
            )
        end
    },

    [tags.color3f] = {
        size = 12,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writef32(buf, offset, val.R)
                buffer.writef32(buf, offset + 4, val.G)
                buffer.writef32(buf, offset + 8, val.B)
                offset += 12
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = Color3.new(
                    buffer.readf32(buf, at),
                    buffer.readf32(buf, at + 4),
                    buffer.readf32(buf, at + 8)
                )
                at += 12
            end
        end,

        write = function(buf, offset, val)
            buffer.writef32(buf, offset, val.R)
            buffer.writef32(buf, offset + 4, val.G)
            buffer.writef32(buf, offset + 8, val.B)
        end,
        
        read = function(buf, offset)
            return Color3.new(
                buffer.readf32(buf, offset),
                buffer.readf32(buf, offset + 4),
                buffer.readf32(buf, offset + 8)
            )
        end
    },

    [tags.bool] = {
        size = 1,

        writer = function(buf, t)
            local offset = 1
        
            for i = 1, #t do
                local val = t[i]
                buffer.writeu8(buf, offset, val and 1 or 0)
                offset += 1
            end
        end,

        reader = function(buf, t, n)
            local at = 1
            for i = 1, n do
                t[i] = buffer.readu8(buf, at) == 1
                at += 1
            end
        end,

        write = function(buf, offset, val)
            buffer.writeu8(buf, offset, val and 1 or 0)
        end,
        
        read = function(buf, offset)
            return buffer.readu8(buf, offset) == 1
        end
    }
}

---
-- API
---

function transform_table_buffer.getBufferFromArray(array: {any}, typ: string?): buffer?
    local n = #array
    local type_name = typ or typeof(array[1])
    local item_tag = tag_lookup[type_name]
    local branch = master_table[item_tag]

    local buf_size = 1

    if item_tag == tags.String then
        local offsets = table.create(n)

        for i = 1, n do
            local str = array[i]
            local str_size = #str

            offsets[i] = buf_size
            buf_size += str_size + 2
        end

        local buf = buffer.create(buf_size)
        buffer.writeu8(buf, 0, item_tag)

        for i = 1, n do
            local str = array[i]
            local offset = offsets[i]
            local str_size = #str

            buffer.writeu16(buf, offset, str_size)
            buffer.writestring(buf, offset + 2, str)
        end

        return buf
    end

    buf_size += n * branch.size

    local buf = buffer.create(buf_size)
    buffer.writeu8(buf, 0, item_tag)

    branch.writer(buf, array)

    return buf
end

function transform_table_buffer.getBufferFromHashmap(hashmap: {[string]: any}, typ: string?): buffer?
    local _, first_val = next(hashmap)

    local tag = tag_lookup[typ or typeof(first_val)]
    
    local branch = master_table[tag]
    local branch_size = branch.size

    first_val = nil
    
    local hashmap_len = 0
    local buf_size = 3

    local is_dyn_size = branch_size == nil

    for key, val in pairs(hashmap) do
        hashmap_len += 1
        local item_size = 
            if is_dyn_size then branch.measure(val) else branch_size
        buf_size += 1 + #key + item_size
    end

    local buf = buffer.create(buf_size)
    buffer.writeu8(buf, 0, bit32.bor(0x80, tag))
    buffer.writeu16(buf, 1, hashmap_len)

    local at = 3
    for key, val in pairs(hashmap) do
        local key_len = #key
        local item_size = 
            if is_dyn_size then branch.measure(val) else branch_size

        buffer.writeu8(buf, at, key_len)
        buffer.writestring(buf, at + 1, key)
        at += 1 + key_len

        branch.write(buf, at, val)
        at += item_size
    end

    return buf
end

function transform_table_buffer.decode(buf: buffer): {any}?
    local buf_size = buffer.len(buf)

    local raw_tag = buffer.readu8(buf, 0)
    
    local is_hashmap = bit32.band(0x80, raw_tag) ~= 0
    local tag = bit32.band(0x7F, raw_tag)

    local branch = master_table[tag]
    local branch_size = branch.size

    if is_hashmap then
        local result = {}

        local at = 3
        local key_count = buffer.readu16(buf, 1)
        local branch_read = branch.read

        for i = 1, key_count do
            local key_len = buffer.readu8(buf, at)
            local key = buffer.readstring(buf, at + 1, key_len)
            at += 1 + key_len

            local val, consumed
            if branch_size then
                val = branch_read(buf, at)
                consumed = branch_size
            else
                val, consumed = branch_read(buf, at)
            end
            result[key] = val
            at += consumed
        end

        return result
    else
        if not branch_size then
            local at = 1
            local t = {}
            local count = 0

            while at < buf_size do
                count += 1
                local str_size = buffer.readu16(buf, at)
                at += 2

                local future = at + str_size

                t[count] = buffer.readstring(buf, at, str_size)
                at = future
            end
    
            return t
        else
            local reader = branch.reader
        
            local content_size = buf_size - 1
            if content_size % branch_size ~= 0 then return nil end
            local n = content_size / branch_size
        
            local t = table.create(n)
            reader(buf, t, n)
            return t
        end
    end
end

-- Expose internal utils

transform_table_buffer.tags = tags
transform_table_buffer.tag_lookup = tag_lookup
transform_table_buffer.master_table = master_table

return transform_table_buffer
