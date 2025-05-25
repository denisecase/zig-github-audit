# zig-github-audit

> A simple cross-platform GitHub repo fetcher using Zig — a modern, C-like language for building fast, portable executables.

## Quick Start: Use On Windows (without building)

Just download [zig-out/bin/github_audit.exe](zig-out/bin/github_audit.exe) to your machine. 
Then open a PowerShell terminal in the folder containing the executable and run:
Replace `denisecase` with your GitHub username.

```pwsh
./github_audit.exe denisecase
```

Important: You will need `curl` installed and available on your system PATH.

## Prerequisites to Build and Run Locally

- `curl` installed and in your path. 
- Zig installed and added to your system PATH.

Download a prebuilt Zig release from <https://ziglang.org/download/>.
Extract it somewhere **outside** your cloud-synced directories (e.g., not OneDrive or iCloud).
Find the path to `zig.exe` and add that folder to your system `PATH`.
**Restart all** open VS Code windows to ensure the terminal picks up the updated environment.

## Verify Installation

Start a project, e.g. fork and clone this repo or start your own in GitHub with a default README.md.
Clone your GitHub repo down to your machine. 
Open your repo folder in VS Code. In VS Code, Terminal / New Terminal.
In a PowerShell terminal:

```pwsh
$PSVersionTable.PSEdition
$env:Path -split ';'
zig version
```

## Run Locally

To run a the zig file directly without building an executable, 
use the following command. 
Replace the username with your GitHub username. 
Note the space after the dash-dash. 

```shell
zig build run -- denisecase
```

## Publish for Release

Build an optimized executable:

```shell
zig build install -Doptimize=ReleaseSafe
```

This generates:

- `zig-out/bin/github_audit.exe` - list of GitHub repos for the given username
- `zig-out/bin/github_audit.pdb` - program database file with debug info (optional)

## Reference

- [REF_BUILD.md](REF_BUILD.md) - more about the build.zig script
- [REF_EXAMPLES.md](REF_EXAMPLES.md) - sample Zig source files
- [REF_EXAMPLES+INPUT.md](REF_EXAMPLES+INPUT.md) - how input.txt is used in the examples
- [REF_MEMORY.md](REF_MEMORY.md) - more about Zig memory allocators (and pointers)

## Links

- [Ziglang Website](https://ziglang.org/)
- [Ziglang Zig GitHub Repository](https://github.com/ziglang/zig)

## Tested With

- Windows 11
- VS Code
- PowerShell Core
- Zig 0.15.0-dev.631+9a3540d61

Note: Zig is under active development. Updates may break existing code.
