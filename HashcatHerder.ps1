####################################################################################
# 
# HashcatHerder.ps1 
#
# Description: 
# Automates running hascat over multiple wordlists. Smallest to largest
#
# Example: 
# Script options --hash type --location of hash to crack --location of pass files --output log directory
#
# Directory:
# .\HashcatHerder.ps1 -hFile D:\CBH\HashcatHerder\sha1-100.txt -pDir D:\CBH\HashcatHerder\pList\ -hType 100
#
# File:
# .\HashcatHerder.ps1 -hFile D:\CBH\HashcatHerder\sha1-100.txt -pDir D:\CBH\HashcatHerder\pList\crackstation.txt -hType 100
#
# Author: 
# Hue B. Solutions LLC, CBHue
#
####################################################################################

[CmdletBinding()]
Param (
    [Parameter(Mandatory=$true)]
    [String] $hType,
    [String] $hFile,
    [String] $pDir, 
    [String] $OutputDelimiter = "`n"
)

$DebugPreference = "Continue"

function Set-Output($log){
    Write-Output $log | Out-File $logFile -Encoding "ascii" -Append
    Write-Debug $log
}

function Get-cracked {
    Set-Output("")
    Set-Output("-----------------------------------------------")
    Set-Output("[*] Cracked Passwords: ")
    $o = Get-ChildItem $baseDIR -Filter *.log 
    Foreach ($f in $o) {
        $fc = Get-Content $f.FullName 
        Set-Output("$f.Name")
        Set-Output("$fc")
    }
    Set-Output("-----------------------------------------------")
    Set-Output("[*] PotFile Passwords: ")
    $Parms = "-m " + $hType + " --show " + $hFileBK
    $p = $Parms.Split(" ")
    $out = & $cmd $p
    Set-Output("$out")
    Set-Output("-----------------------------------------------")
}

function Get-hashFile {
    $count = 0
    Try{ 
        $hashFile = Get-Content $hFile 
        $count = ($hashFile | Measure-Object –Line).lines
    }
    Catch [system.exception] {
        write-output "We had an issue w/ $hFile ..."
        Write-Output $Error
    }
    return $count
}

function Herd-Cats {
    Set-Output("")
    Set-Output("My directory is $baseDIR")
    Set-Output("Logfile: $logFile")
    Set-Output("-----------------------------------------------")

    $c=0
    $ohashCount = Get-hashFile 
    $tc = $pwListDIR.Length
    $global:sw = [Diagnostics.Stopwatch]::StartNew()

    Foreach ($pwFile in $pwListDIR) {
        $c++
        $hashCount = Get-hashFile
        if ($hashCount -lt 1) { Set-Output("$($sw.Elapsed) [*] All Hashes cracked"); break }
        if ($pwFile -eq $null) {continue}
        if ([IO.Path]::GetExtension($pwFile) -ne ".txt" ) { continue }

        $oFile = $baseDIR + "\CatHerder_" + $now + "_" + $pwFile.Name + ".log"
        Set-Output("") 
        Set-Output("-----------------------------------------------")
        Set-Output("[*] $hashCount of $ohashCount hashes left to crack ...")        
        Set-Output("[*] $($sw.Elapsed) Working on $pwFile")
        Set-Output("[*] Outfile $oFile")
        
        $Parms = "-O --remove --session " + $now + " -o " + $oFile +" -m " + $hType + " " + $hFile + " " + $pwFile.FullName
        $p = $Parms.Split(" ")
        & $cmd $p

        Set-Output("[*] $($sw.Elapsed) Done With $pwFile ... $c of $tc")
        $hashCount = Get-hashFile
        Set-Output("[*] $hashCount out of $ohashCount hashes left to crack ...")
        Set-Output("-----------------------------------------------")
        Set-Output("")

        Start-Sleep -s 5
    }

    $hashCount = Get-hashFile
    Set-Output("-----------------------------------------------")
    Set-Output("$($sw.Elapsed) Done ... $hashCount hashes not cracked")

}

# Setup hashcat Working Directory
$dir = "D:\CBH\hashcat-4.2.1"
$cmd = $dir + '\hashcat64.exe' 
pushd $dir

# Setup Logfile directory
$now = $(get-date -f MMddyyyy_HHmmss)
$bDIR = Split-Path -Path $hFile 
$bFile = Split-Path -Path $hFile -Leaf 
$baseDIR = $bDIR + "\" + $now 
New-Item -Path $baseDIR -ItemType directory
$logFile = $baseDIR + "\CatHerder_" + $now + ".txt"

# Get wordlists
$pwListDIR = Get-ChildItem $pDir -Filter *.txt | sort Length 

# Preserve the hashfile
Copy-Item $hFile -Destination $baseDIR
$hFileBK = $hFile
$hFile = $baseDIR + "\"  + $bFile

# Main Function
Herd-Cats

# Print Results
Get-cracked

popd
$sw.Stop()