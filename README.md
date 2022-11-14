# Process injection

Simple script to automate creating a powershell script that injects shellcode into the `explorer` process.

## Usage

`PS > .\generate-script.ps1 <shellcode filename> <script filename>`

shellcode filename: raw shellcode to inject
script filename: powershell script to create

## References

- [shelloader](https://github.com/john-xor/shelloader)
- [Inspecting a PowerShell Cobalt Strike Beacon](https://forensicitguy.github.io/inspecting-powershell-cobalt-strike-beacon/)
- [PowerShell Obfuscation](https://github.com/gh0x0st/Invoke-PSObfuscation/blob/main/layer-0-obfuscation.md)
