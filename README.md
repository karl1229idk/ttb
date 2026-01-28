<!--
SPDX-FileCopyrightText: 2026 karl_dev1229 <karl1229idk@gmail.com>

SPDX-License-Identifier: MPL-2.0
-->
# transform_table_buffer (TTB)
High performance Roblox serializer to seamlessly transform ```array/hashmap``` <-> ```buffer```

## Why TTB & TTBW?
- **Minimal Buffer:** size = (1 + element bytes)
- **Zero-Dependency:** download it, and plug-and-play
- **Dynamic Typed:** no need to wait for IDL compile, which slow down the development process
- **Type Infer:** you don't need to pass in type name, feel free to skip it
- **Explicit Typing:** you can force TTB to use a type you want, for example, u8 instead of f64(default)
- **HashMap Support:** support HashMap for lazy-devs, don't need to transform to array first
- **Safety with TTBW:** TTBW guarantee the TTB to not crash

## Supported Types
| Types | Size (bytes) | Notes
| :--- | :--- | :--- |
| number / f64 | 8 | Standard Luau number type |
| string |  2 + N | Length-prefixed (max 64KB) |
| CFrame | 48 | Complete lossless CFrame |
| f32 | 4 | 32 bit float |
| u8 | 1 | Unsigned 8 bit integer |
| u16 | 2 | Unsigned 16 bit integer |
| i32 | 4 | Signed 32 bit integer |
| Vector3 | 12 | Raw float packing |
| Vector2 | 8 | Raw float packing |
| Color3 | 3 | Compressed |
| Color3F | 12 | Uncompressed |
| boolean | 1 | 7-bit aligned |

## Disclaimer
***Safety is guaranteed by **YOU**, not the <ins>library</ins>!***
- **No Nesting:** TTB is designed for flat data streams, it is *unsupported* and will *never* be supported
- **Strict Type:** Passing unsupported type or wrong argument will be resulted in undefined behavior/crash
- **Hashmap Rule:** Key must be string (max 255 bytes), Max 65535 pairs per map

## TTBW: The offical TTB wrapper
If you are processing data from **untrusted source**, TTBW will be your best friend!
- **Crash Preventation:** Prevent hard errors/terminations from malformed buffers
- **Validation:** Perform boundary checks/type checkings before TTB execute
- **Usage:** Always check if return value is ```nil```. ```nil``` indicates corrupted or malformed data

## Usage
### TTB Serialization
```lua
local ttb = require("path/to/TTB")
local data = { Vector3.new(1, 2, 3), Vector3.new(1, 2, 3) }
local buf = ttb.getBufferFromArray(
    data --,
    --"Vector3" -- Feel free to not pass in type
                -- TTB will infer it for you!
)

local decoded = ttb.decode(buf)
assert(data[1] == decoded[1] and decoded[2] == data[2])

local map = { player1 = 10, player2 = 20 }
local buf = ttb.getBufferFromHashmap(
    map,
    "u8" -- u8, u16, i32, f32, f64 are supported
         -- Without telling, TTB assume f64 for numbers
)
local decoded = ttb.decode(buf)
assert(map.player1 == decoded.player1 and decoded.player2 == map.player2)
```
### TTBW Serialization
```lua
local ttbw = require("path/to/TTB/TTBW")
local decoded = ttbw.safeDecode(receivedBuffer)

if decoded then
    print("Processing")
else
    warn("Corrupted/Malformed buffer detected")
end
```

## License
Licensed under [MPL-2.0](https://www.mozilla.org/MPL/2.0/)\
[REUSE 3.3](https://reuse.software/spec-3.3/) compliant

## Zen of TTB
- Do one thing and do it well
- Explicit > Implicit
- **Performance > DRY**
- Safety belongs to users
