$ErrorActionPreference='Stop'
$new='seb'
$tag='hashedQuitPassword</key><string>'
$nh=(([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($new))|%{$_.ToString('X2')})-join '')
Write-Host "pwn ready -> $new" -ForegroundColor Cyan
Add-Type -TypeDefinition @'
using System;using System.Runtime.InteropServices;
public class M{
 [DllImport("kernel32.dll")]public static extern IntPtr OpenProcess(int a,bool i,int p);
 [DllImport("kernel32.dll")]public static extern bool ReadProcessMemory(IntPtr h,IntPtr a,byte[] b,int s,out IntPtr r);
 [DllImport("kernel32.dll")]public static extern bool WriteProcessMemory(IntPtr h,IntPtr a,byte[] b,int s,out IntPtr w);
 [DllImport("kernel32.dll")]public static extern int VirtualQueryEx(IntPtr h,IntPtr a,out MBI m,int l);
 [StructLayout(LayoutKind.Sequential)]public struct MBI{public IntPtr B;public IntPtr A;public uint P;public IntPtr S;public uint St;public uint Pr;public uint T;}}
'@
while($true){
 $p=Get-Process SafeExamBrowser,SafeExamBrowser.Client -EA 0 | Select-Object -First 1
 if(-not $p){Write-Host -NoNewline ".";Start-Sleep 1;continue}
 $h=[M]::OpenProcess(0x1F0FFF,$false,$p.Id)
 if($h -eq [IntPtr]::Zero){Write-Host "x";Start-Sleep 1;continue}
 foreach($u in 0,1){
  $e = if($u){[Text.Encoding]::Unicode}else{[Text.Encoding]::ASCII}
  $mul = if($u){2}else{1}
  $nb = $e.GetBytes($nh)
  $a=[IntPtr]::Zero;$mbi=New-Object M+MBI;$n=0
  while([M]::VirtualQueryEx($h,$a,[ref]$mbi,[Runtime.InteropServices.Marshal]::SizeOf($mbi)) -ne 0){
   $sz=$mbi.S.ToInt64()
   if($mbi.St -eq 0x1000 -and $sz -gt 0 -and $sz -lt 64MB){
    for($o=0;$o -lt $sz;$o+=2MB){
     $ln=[Math]::Min(2MB,$sz-$o);$buf=New-Object byte[] $ln;$r=[IntPtr]::Zero
     if([M]::ReadProcessMemory($h,[IntPtr]($a.ToInt64()+$o),$buf,$ln,[ref]$r)){
      $s=$e.GetString($buf);$i=0
      while(($i=$s.IndexOf($tag,$i)) -ge 0){
       $st=$i+$tag.Length
       $v=$s.Substring($st,[Math]::Min(64,$s.Length-$st))
       if($v -match '^[0-9a-fA-F]{64}$'){
        $j=0
        while(($j=$s.IndexOf($v,$j)) -ge 0){
         $w=[IntPtr]::Zero
         if([M]::WriteProcessMemory($h,[IntPtr]($a.ToInt64()+$o+$j*$mul),$nb,$nb.Length,[ref]$w)){$n++}
         $j+=$v.Length
        }
       }
       $i=$st+64
      }
     }
    }
   }
   $a=[IntPtr]($a.ToInt64()+$sz); if($a.ToInt64() -le 0){break}
  }
  if($n){Write-Host "`nPATCHED $n runs (enc=$u)" -ForegroundColor Green}
 }
 Start-Sleep -Milliseconds 1200
}