# Memory Allocation

## Zig Requires Explicit Memory Allocation

Zig does not have a garbage collector or automatic memory management.
Instead:
- We allocate memory when needed
- We free memory when it's no longer needed

This gives us fine-grained control over performance, safety, and resource usage.

It also means we need to learn about **pointers** — a way to refer to the location (address) of a value in memory.

## Pointers and Dereferencing in Zig

When you pass an allocator (or any complex value) to a function, you usually pass a **pointer** to it, using the `&` symbol:

```zig
var allocator = std.heap.page_allocator;
try someFunction(&allocator); // pass a pointer
```

Inside that function, the parameter might look like:

```zig
fn someFunction(allocator_ptr: *std.mem.Allocator) { ... }
```

To access the actual value the pointer refers to, use .* (dereference the pointer):

```zig
const allocator = allocator_ptr.*; // now a value, not a pointer
```

You dereference a pointer when the called function needs a value (not a pointer), for example:

```zig
// needs value, not pointer
const url = try std.fmt.allocPrint(allocator, ...); 
```

Conversely, some functions like `.free(...)` expect the allocator pointer, so pass it directly.

| If the function expects... | Pass in           | Notes                   |
| -------------------------- | ----------------- | ----------------------- |
| `Allocator` (a value)      | `allocator_ptr.*` | Dereference the pointer |
| `*Allocator` (a pointer)   | `allocator_ptr`   | Already a pointer       |


## When To Use a Memory Allocator

| Situation                             | Example                               | Explanation                                           |
|---------------------------------------|---------------------------------------|-------------------------------------------------------|
| Allocating a string or buffer         | `std.fmt.allocPrint(...)`             | You build a formatted string at runtime.              |
| Parsing JSON or other dynamic formats | `std.json.parseFromSlice(...)`        | JSON needs to store parsed values in memory.          |
| Building data structures              | `ArrayList`, `HashMap`, `StringHashMap` | These grow in size at runtime — they need an allocator. |
| Using an arena or bump allocator      | `std.heap.ArenaAllocator`             | For bulk allocation with one-time freeing.            |
| Temporary test buffers                | `try allocator.alloc(u8, 1024)`       | Useful for temporary working memory or tests.         |

## When a Memory Allocator is NOT Required


| Situation               | Example                             | Why                                 |
|-------------------------|-------------------------------------|--------------------------------------|
| Fixed-size arrays       | `var arr: [10]u8 = undefined;`       | Size known at compile time.          |
| Stack memory            | `var buffer: [1024]u8 = undefined;`  | Allocated on the stack.              |
| Constant strings        | `const msg = "Hello";`               | Stored in binary — no allocation.    |
| Static data structures  | `var table: [100]MyStruct = undefined;` | No dynamic sizing needed.         |


