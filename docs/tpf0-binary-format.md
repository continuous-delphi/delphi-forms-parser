# TPF0 Binary Format Specification

Reference documentation for the Delphi binary form data format (TPF0),
used by `.dfm` and `.fmx` files when stored in binary mode.

This specification is derived from the `delphi-forms-parser` implementation
(`TDfmBinaryReader` / `TDfmBinaryWriter`) and verified against binary DFM
files produced by Delphi 7 through Delphi 12. The only prior public
documentation is a blog post by IS4Code (March 2022) which covers the
basics but omits 8 of the 22 value types, misidentifies `vaExtended` as
8-byte double, and does not document object kind flags or encoding details.

All multi-byte integers are little-endian.

---

## 1. File Signature

A binary DFM stream begins with one of two signatures:

| Variant | Bytes | Description |
|---------|-------|-------------|
| Standard | `FF 54 50 46 30` | `$FF` prefix + ASCII `TPF0` (5 bytes) |
| Bare | `54 50 46 30` | ASCII `TPF0` without prefix (4 bytes) |

The standard variant (with `$FF` prefix) is what Delphi's streaming system
produces. The bare variant appears in some hand-constructed or third-party
tool output. Readers should accept both forms.

After the signature, the stream contains exactly one root object.

---

## 2. Object

An object encodes a component instance with its class, name, properties,
and child components.

### 2.1 Class Name Length Byte

The first byte encodes both the class name length and object kind flags
in the high nibble:

```
  7  6  5  4  3  2  1  0
 [-- flags --][-- len --]
```

| High nibble | Object kind |
|-------------|-------------|
| `$00` | `object` (normal) |
| `$10` | `inherited` |
| `$20` | `inline` |

The low nibble (bits 3..0) gives the class name length in bytes. This
limits binary class names to 15 characters when flags are present, though
in practice Delphi class names this short are rare and the IDE may use a
different encoding for longer names with flags.

**Note:** When the high nibble is `$00` (normal object), the full byte is
the class name length, supporting names up to 255 characters. The flag
bits only consume the high nibble when non-zero.

### 2.2 Class Name

`ClassNameLen` bytes of ANSI-encoded class name (no length prefix -- the
length was in the preceding byte). If `ClassNameLen` is 0, this is the
end-of-children sentinel (see Section 2.5).

### 2.3 Object Name

A short string (Section 4.1): 1-byte length prefix + ANSI bytes. This is
the component's `Name` property (e.g., `Button1`, `Panel1`).

### 2.4 Properties

A sequence of property records (Section 3), terminated by a zero byte
(a property name with length 0).

### 2.5 Children

A sequence of child objects (recursive), terminated by a zero byte. The
reader peeks at the next byte: if it is `$00`, the children list is done;
otherwise it is the start of the next child's class name length byte.

### 2.6 Complete Object Layout

```
[ClassNameLenByte]          1 byte (flags | length)
[ClassName]                 ClassNameLen bytes (ANSI)
[NameLen]                   1 byte
[Name]                      NameLen bytes (ANSI)
[Property]*                 repeated
[00]                        end of properties
[ChildObject]*              repeated (recursive)
[00]                        end of children
```

---

## 3. Property

Each property is a name-value pair.

```
[NameLen]                   1 byte
[Name]                      NameLen bytes (ANSI)
[Value]                     value record (Section 5)
```

The property list ends when `NameLen` is `$00`.

Property names are ANSI-encoded Pascal identifiers. Dotted names
(e.g., `Font.Name`) are valid and represent sub-property paths.

---

## 4. String Encodings

The format uses several string encodings, distinguished by their value
type tag or context.

### 4.1 Short String (Symbol)

Used for class names, object names, property names, identifiers, and
set member names.

```
[Len]                       1 byte (0..255)
[Data]                      Len bytes, ANSI-encoded
```

A zero-length short string (`Len = $00`) serves as a list terminator
in multiple contexts (properties, children, sets).

### 4.2 Long String (vaString, vaLString)

`vaString` uses a 1-byte length prefix (like a short string) but appears
as a property value. `vaLString` uses a 4-byte (Int32) length prefix.
Both are ANSI-encoded.

### 4.3 Wide String (vaWString, vaUString)

4-byte (Int32) length prefix giving the number of *characters* (not
bytes). Data is `Length * 2` bytes, UTF-16LE encoded.

### 4.4 UTF-8 String (vaUTF8String)

4-byte (Int32) length prefix giving the number of *bytes*. Data is
UTF-8 encoded. This is the default string type in modern Delphi (2009+).

---

## 5. Value Types

Every property value begins with a 1-byte type tag. The following table
lists all 22 value types.

| Tag | Hex | Name | Payload | Description |
|-----|-----|------|---------|-------------|
| 1 | `$01` | vaList | values + `$00` | Ordered list of values |
| 2 | `$02` | vaInt8 | 1 byte | Signed 8-bit integer (-128..127) |
| 3 | `$03` | vaInt16 | 2 bytes | Signed 16-bit integer (little-endian) |
| 4 | `$04` | vaInt32 | 4 bytes | Signed 32-bit integer (little-endian) |
| 5 | `$05` | vaExtended | 10 bytes | 80-bit extended precision float |
| 6 | `$06` | vaString | 1-byte len + data | ANSI short string |
| 7 | `$07` | vaIdent | short string | Identifier / enumeration value |
| 8 | `$08` | vaFalse | (none) | Boolean False |
| 9 | `$09` | vaTrue | (none) | Boolean True |
| 10 | `$0A` | vaBinary | Int32 len + data | Raw binary blob |
| 11 | `$0B` | vaSet | short strings + `$00` | Set of identifiers |
| 12 | `$0C` | vaLString | Int32 len + data | ANSI long string |
| 13 | `$0D` | vaNil | (none) | Nil reference |
| 14 | `$0E` | vaCollection | items + `$00` | Collection of item objects |
| 15 | `$0F` | vaSingle | 4 bytes | IEEE 754 single-precision float |
| 16 | `$10` | vaDouble | 8 bytes | IEEE 754 double-precision float |
| 17 | `$11` | vaCurrency | 8 bytes | Delphi Currency (Int64 / 10000) |
| 18 | `$12` | vaDate | 8 bytes | TDateTime as IEEE 754 double |
| 19 | `$13` | vaWString | Int32 charcount + UTF-16LE | Wide string |
| 20 | `$14` | vaInt64 | 8 bytes | Signed 64-bit integer (little-endian) |
| 21 | `$15` | vaUTF8String | Int32 bytelen + UTF-8 | UTF-8 string |
| 22 | `$16` | vaUString | Int32 charcount + UTF-16LE | Unicode string |

### 5.1 Integer Values (vaInt8, vaInt16, vaInt32, vaInt64)

All integer types are signed and little-endian. Writers typically choose
the smallest type that can represent the value:

| Type | Range |
|------|-------|
| vaInt8 | -128 to 127 |
| vaInt16 | -32768 to 32767 |
| vaInt32 | -2147483648 to 2147483647 |
| vaInt64 | Full Int64 range |

### 5.2 Floating-Point Values

**vaSingle ($0F):** 4 bytes, IEEE 754 single-precision.

**vaDouble ($10):** 8 bytes, IEEE 754 double-precision.

**vaExtended ($05):** 10 bytes, Intel 80-bit extended precision. This is
the native `Extended` type on 32-bit Delphi (Win32). On 64-bit Windows,
`Extended` is aliased to `Double` (8 bytes), but the binary format always
stores 10 bytes. Readers on Win64 must manually convert the 80-bit
representation. For round-trip fidelity, the raw 10 bytes should be
preserved.

**vaCurrency ($11):** 8 bytes, stored as a signed 64-bit integer that
represents the value multiplied by 10,000 (Delphi's `Currency` type).

**vaDate ($12):** 8 bytes, stored as an IEEE 754 double representing a
Delphi `TDateTime` value (days since 1899-12-30, fractional part is
time of day).

### 5.3 String Values

See Section 4 for encoding details. Summary of length prefix formats:

| Type | Length prefix | Encoding | Length unit |
|------|-------------|----------|------------|
| vaString | 1 byte | ANSI | bytes |
| vaLString | Int32 | ANSI | bytes |
| vaWString | Int32 | UTF-16LE | characters |
| vaUTF8String | Int32 | UTF-8 | bytes |
| vaUString | Int32 | UTF-16LE | characters |

### 5.4 Boolean Values (vaFalse, vaTrue)

No payload -- the type tag alone encodes the value.

### 5.5 Identifier (vaIdent)

A short string (1-byte length + ANSI data) representing an enumeration
value, symbolic constant, or component reference. Examples: `clBtnFace`,
`alClient`, `poScreenCenter`, `Button1`.

### 5.6 Nil (vaNil)

No payload. Represents a nil object reference. Corresponds to `nil` in
text DFM format.

### 5.7 Set (vaSet)

A sequence of short strings (identifiers), terminated by an empty short
string (length byte `$00`). Represents a Delphi set value.

```
[$0B]                       vaSet tag
[ShortString]*              set member identifiers
[$00]                       empty string = end of set
```

Example: `[akLeft, akTop, akRight]` encodes as three short strings
(`akLeft`, `akTop`, `akRight`) followed by `$00`.

### 5.8 Binary Data (vaBinary)

```
[$0A]                       vaBinary tag
[Int32]                     byte count (little-endian)
[Data]                      raw bytes
```

Used for embedded images, custom streamed data, and other opaque blobs.
In text DFM format, this corresponds to the `{ hex }` block syntax.

### 5.9 List (vaList)

An ordered sequence of values of any type, terminated by a `$00` byte
(which is not a valid value type tag in list context -- tag `$00` is
reserved as the terminator).

```
[$01]                       vaList tag
[Value]*                    any value type (recursive)
[$00]                       end of list
```

Used for properties like `TStrings.Strings` where the value is a list
of strings, or `Ranges` where the value is a list of integers.

### 5.10 Collection (vaCollection)

A sequence of collection items, terminated by a `$00` byte.

```
[$0E]                       vaCollection tag
[CollectionItem]*           repeated items
[$00]                       end of collection
```

Each collection item consists of:

```
[ItemIndex]                 integer value (vaInt8/16/32/64 with tag)
[Property]*                 property records (same as object properties)
[$00]                       end of item properties
```

The item index is encoded as a full integer value (type tag + payload),
using the smallest integer type that fits. It corresponds to the index
shown in text DFM format (e.g., `item` implicitly gets sequential
indices; explicit indices are rare).

---

## 6. Complete Stream Layout

```
[$FF]                       optional prefix byte
[TPF0]                      4-byte ASCII signature
[RootObject]                single root object (Section 2)
                            (stream ends after root object)
```

The root object is typically the form or data module itself. Its children
are the components placed on the form.

---

## 7. Historical Notes

- The TPF0 format has been stable since Delphi 1 (1995). Value types
  through `vaCollection` ($0E) were present from the start.
- `vaSingle`, `vaDouble`, `vaCurrency`, `vaDate` ($0F..$12) were added
  in Delphi 3/4 to support additional numeric types without overloading
  `vaExtended`.
- `vaWString` ($13) was added for Delphi's `WideString` support.
- `vaInt64` ($14) was added when Delphi gained 64-bit integer support.
- `vaUTF8String` ($15) appeared in Delphi 2009 with the Unicode transition.
- `vaUString` ($16) was added for `UnicodeString` (distinct from
  `WideString` in reference counting semantics, though the binary
  encoding is identical to `vaWString`).

---

## 8. References

- Embarcadero `System.Classes.pas` -- `TReader` / `TWriter` source code
  (the authoritative implementation).
- `delphi-forms-parser` source: `Delphi.Forms.BinaryReader.pas`,
  `Delphi.Forms.BinaryWriter.pas` -- tested against binary DFM files
  from Delphi 7 through Delphi 12 with full round-trip verification.