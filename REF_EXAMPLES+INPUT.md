# Zig Input

- Windows uses UTF-16 internally.
- The terminal uses codepages (not UTF-8 by default).
- Zig's std.process.Child converts args assuming clean UTF-8, but Windows console input is not guaranteed to be clean UTF-8.
- There is no universal way to safely read valid UTF-8 from PowerShell stdin without jumping through hoops like setting code pages or using a proper terminal emulator.
- Solution: Read from a .txt file

| Input Method  | Works on Windows   | Works on Linux/macOS | Cross-platform | Reliable |
| ------------- | ------------------ | -------------------- | -------------- | -------- |
| `stdin` (raw) | ❌ (corrupts UTF-8) | ✅                 | ❌            | ❌        |
| `.txt` file   | ✅                  | ✅                 | ✅            | ✅        |
| CLI args      | ✅ (with care)      | ✅                 | ✅            | ✅        |
