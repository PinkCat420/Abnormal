.SYNOPSIS
Recursively scans a directory for all video files and re-encodes them
to H.265/HEVC using an NVIDIA GPU (CUDA) to save space.

v9 FIXES:
- CRITICAL FIX: Removed the buggy "Pass 1" grouping logic. The script
now processes EVERY file.
- CRITICAL FIX: Solved the race condition by making output file names
100% unique (e.g., "video.mkv" -> "video.mkv.mp4").
- CRITICAL FIX: Removed the buggy and destructive "Pass 5: Restore" pass.
The script is now much safer and only deletes temp files.

.NOTES
REQUIREMENTS:
1. PowerShell 7.2 or newer (for ForEach-Object -Parallel)
2. FFmpeg & FFprobe: Must be in your system's PATH.
3. NVIDIA GPU: Required for the 'hevc_nvenc' encoder.
#>

# --- 1. CONFIGURATION ---

# The root folder you want to scan
$SourcePath = "E:\Gooner\MEGA"

# The folder where larger files will be moved (will be created)
$BackupPath = "E:\Gooner\Temp\V1"

# A log file to record all actions
$LogFile = "E:\Gooner\Temp\encoding_log_$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').txt"

# ---
# CRITICAL: YOU MUST SET THIS TO 3.
# Your unpatched 3080 driver has a HARD-CODED limit of 3 encodes.
# Setting this to 5 is the reason you get the "No capable devices found" error.
# This is not for lag. It is to stop the driver from rejecting the jobs.
# ---
$ThrottleLimit = 3

# The "High Quality" setting for H.265.
$QualityLevel = 24

# The FFmpeg preset for the `hevc_nvenc` encoder. p7 is highest quality, p5 is faster with slightly less quality.
$FFmpegPreset = "p7"

# --- Audio Settings ---
# Set to $true to re-encode audio, potentially saving more space. Set to $false to copy the original audio track.
$EnableAudioReencoding = $true
$AudioCodec = "aac"
$AudioBitrate = "128k"

# Add any video extensions you want to check
$VideoExtensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.m4v', '.flv', '.webm', '.mpg', '.mpeg')

# The prefix for our temporary files
$TempPrefix = "temp_recode_"

# We force .mp4 because it's universally compatible with H.265.
$OutputExtension = ".mp4"

# --- 2. INITIALIZATION ---

Write-Host "🚀 Starting H.265 Re-encoding Project..."

# --- 2.5: PRE-FLIGHT CHECKS ---
Write-Host "🕵️  Running Pre-flight Checks..."
$CriticalErrors = @()
$Warnings = @()

# Critical Check 1: FFmpeg exists
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    $CriticalErrors += "CRITICAL: ffmpeg.exe not found in your system's PATH. This is required for video encoding."
}

# Critical Check 2: FFprobe exists
if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
    $CriticalErrors += "CRITICAL: ffprobe.exe not found in your system's PATH. This is required for video analysis."
}

# Critical Check 3: SourcePath exists
if (-not (Test-Path -Path $SourcePath -PathType Container)) {
    $CriticalErrors += "CRITICAL: The Source Path '$SourcePath' does not exist or is not a directory."
}

if ($CriticalErrors.Count -gt 0) {
    Write-Host "`n"
    $CriticalErrors | ForEach-Object { Write-Error $_ }
    Write-Host "`n"
    Write-Error "Script cannot continue due to critical errors. Please resolve the issues above and try again."
    exit 1
}

# Non-Critical Check 1: BackupPath exists
if (-not (Test-Path -Path $BackupPath -PathType Container)) {
    $Warnings += @{
        Message = "WARNING: The Backup Path '$BackupPath' does not exist. The script will create it, but this may not be what you intended."
        Fix = "Ensure the specified backup directory is correct. If it is, the script will create it automatically."
    }
}

# Non-Critical Check 2: Write permissions for SourcePath
try {
    $TestFile = Join-Path -Path $SourcePath -ChildPath "temp_permission_test.tmp"
    New-Item -ItemType File -Path $TestFile -ErrorAction Stop | Out-Null
    Remove-Item -Path $TestFile -ErrorAction Stop
} catch {
    $Warnings += @{
        Message = "WARNING: No write permissions in the Source Path '$SourcePath'. The script cannot create temporary files or move originals."
        Fix = "Ensure you have write permissions for the directory '$SourcePath'."
    }
}

# Non-Critical Check 3: Write permissions for BackupPath
if (Test-Path -Path $BackupPath -PathType Container) {
    try {
        $TestFile = Join-Path -Path $BackupPath -ChildPath "temp_permission_test.tmp"
        New-Item -ItemType File -Path $TestFile -ErrorAction Stop | Out-Null
        Remove-Item -Path $TestFile -ErrorAction Stop
    } catch {
        $Warnings += @{
            Message = "WARNING: No write permissions in the Backup Path '$BackupPath'. The script cannot move larger files or failed encodes."
            Fix = "Ensure you have write permissions for the directory '$BackupPath'."
        }
    }
}


# Non-Critical Check 4: Disk Space
$LargestFile = Get-ChildItem -Path $SourcePath -Recurse -File |
    Where-Object { $_.Extension -in $VideoExtensions } |
    Sort-Object -Property Length -Descending |
    Select-Object -First 1

if ($LargestFile) {
    $LargestFileSizeGB = [Math]::Round($LargestFile.Length / 1GB, 2)
    $SourceDrive = [System.IO.Path]::GetPathRoot($SourcePath)
    $BackupDrive = [System.IO.Path]::GetPathRoot($BackupPath)

    $SourceFreeSpace = (Get-PSDrive -Name ($SourceDrive.TrimEnd('\:'))).Free
    $BackupFreeSpace = (Get-PSDrive -Name ($BackupDrive.TrimEnd('\:'))).Free

    if ($SourceFreeSpace -lt $LargestFile.Length) {
        $SourceFreeSpaceGB = [Math]::Round($SourceFreeSpace / 1GB, 2)
        $Warnings += @{
            Message = "WARNING: Low disk space on source drive ($SourceDrive). Available: $($SourceFreeSpaceGB) GB. Largest file: $($LargestFileSizeGB) GB."
            Fix = "Free up at least $($LargestFileSizeGB - $SourceFreeSpaceGB) GB on $SourceDrive."
        }
    }

    if ($BackupFreeSpace -lt $LargestFile.Length) {
        $BackupFreeSpaceGB = [Math]::Round($BackupFreeSpace / 1GB, 2)
        $Warnings += @{
            Message = "WARNING: Low disk space on backup drive ($BackupDrive). Available: $($BackupFreeSpaceGB) GB. Largest file: $($LargestFileSizeGB) GB."
            Fix = "Free up at least $($LargestFileSizeGB - $BackupFreeSpaceGB) GB on $BackupDrive."
        }
    }
}


if ($Warnings.Count -gt 0) {
    Write-Host "`n"
    $Warnings | ForEach-Object {
        Write-Warning $_.Message
        Write-Host "  HOW TO FIX: $($_.Fix)"
        Write-Host ""
    }
    $Choice = Read-Host "Do you want to continue anyway? [Y/N]"
    if ($Choice.ToUpper() -ne 'Y') {
        Write-Error "User aborted the script. Please resolve the issues above."
        exit 1
    }
}

Write-Host "✅ Pre-flight checks passed."

New-Item -ItemType Directory -Path $BackupPath -ErrorAction SilentlyContinue | Out-Null
"Scan started at $(Get-Date)" | Out-File -FilePath $LogFile

# --- 3. PASS 0: CLEANUP ---
Write-Host "🧼 Pass 0: Cleaning up temp files from previous runs..."
$OrphanedFiles = Get-ChildItem -Path $SourcePath -Recurse -File -Filter "$($TempPrefix)*"
$CleanupCounter = 0

foreach ($TempFile in $OrphanedFiles) {
Write-Warning " Deleting orphan: $($TempFile.FullName)"
Remove-Item $TempFile.FullName -ErrorAction SilentlyContinue
$LogEntry = "[{0}] - CLEANUP - Deleted orphan file: {1}" -f (Get-Date), $TempFile.FullName
$LogEntry | Add-Content -Path $LogFile
$CleanupCounter++
}
Write-Host "✅ Cleanup finished. $CleanupCounter files processed."

# --- 4. PASS 1: INVENTORY (SIMPLE) ---
Write-Host "🔍 Pass 1: Taking inventory of all video files..."

# Get ALL files. No more clever grouping.
$AllFiles = Get-ChildItem -Path $SourcePath -Recurse -File |
Where-Object { $_.Extension -in $VideoExtensions }

$TotalCount = $AllFiles.Count

if ($TotalCount -eq 0) {
Write-Warning "No video files found to process."
return
}

# --- Calculate total size and initialize counters ---
$TotalOriginalSize = ($AllFiles | Measure-Object -Property Length -Sum).Sum
$script:TotalSpaceSaved = 0
$script:ProcessedCount = 0
$TotalOriginalSizeGB = [Math]::Round($TotalOriginalSize / 1GB, 2)
$ActivityMessage = "Mass Re-Encode H.265 (Total Job Size: $TotalOriginalSizeGB GB)"

Write-Host "✅ Found $TotalCount video files to process (Total Size: $TotalOriginalSizeGB GB)."
Write-Host "Starting Pass 2 (Parallel Encoding)..."
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# --- 5. PASS 2: PARALLEL PROCESSING ---

$AllFiles | ForEach-Object -Parallel {
# This entire block runs in a separate, parallel thread for EACH file.

$File = $_
$OriginalPath = $File.FullName
$OriginalSize = $File.Length

# --- FIX: Create a 100% unique output name to prevent all race conditions ---
# e.g., "MyVideo.mkv" -> "temp_recode_MyVideo.mkv.mp4"
$UniqueBaseName = $File.Name # This is "MyVideo.mkv"
$TempFileName = "$($using:TempPrefix)$($UniqueBaseName)$($using:OutputExtension)"
$TempOutputPath = Join-Path -Path $File.DirectoryName -ChildPath $TempFileName

# Get Relative Path for structure-preserving backup
$RelativePath = $File.DirectoryName.Replace($using:SourcePath, "")
$BackupDir = Join-Path -Path $using:BackupPath -ChildPath $RelativePath

$Status = ""
$SpaceSaved = 0

try {
# STEP A: Check the codec.
$Codec = ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 -i "$OriginalPath"

if ($Codec -eq 'hevc') {
$Status = "SKIPPED: Already H.265 (Codec: $Codec)"
} else {
# STEP B: Dynamically build and run the FFmpeg command
# We use CPU decoding (-i) for stability and GPU encoding (-c:v hevc_nvenc) for speed.
$ffmpegArgs = [System.Collections.Generic.List[string]]@(
    "-i", "$OriginalPath",
    "-map", "0:v:0", "-map", "0:a?", "-map", "0:s?",
    "-c:v", "hevc_nvenc", "-preset", $using:FFmpegPreset, "-tune", "uhq", "-rc", "constqp", "-qp", $using:QualityLevel,
    "-c:s", "copy"
)

if ($using:EnableAudioReencoding) {
    $ffmpegArgs.Add("-c:a")
    $ffmpegArgs.Add($using:AudioCodec)
    $ffmpegArgs.Add("-b:a")
    $ffmpegArgs.Add($using:AudioBitrate)
} else {
    $ffmpegArgs.Add("-c:a")
    $ffmpegArgs.Add("copy")
}

$ffmpegArgs.Add("-hide_banner")
$ffmpegArgs.Add("-loglevel")
$ffmpegArgs.Add("error")
$ffmpegArgs.Add("-y")
$ffmpegArgs.Add("$TempOutputPath")

# Execute FFmpeg with the argument list and wait for it to finish
$process = Start-Process ffmpeg -ArgumentList $ffmpegArgs -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
# FFmpeg failed
$Status = "ERROR: FFmpeg failed to encode. (Source Codec: $Codec, File: $($File.Name))"
if (Test-Path $TempOutputPath) {
# Create the backup sub-directory and move the failed temp file
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$FailedName = "$($UniqueBaseName)-FAILED-$(Get-Date -Format 'yyyyMMddHHmmss')$($using:OutputExtension)"
$BackupFile = Join-Path -Path $BackupDir -ChildPath $FailedName
Move-Item -Path $TempOutputPath -Destination $BackupFile -ErrorAction SilentlyContinue
}
} else {
# FFmpeg succeeded, now compare sizes
$NewSize = (Get-Item $TempOutputPath).Length

if ($NewSize -lt $OriginalSize) {
# SUCCESS: New file is smaller. Keep it.

# Create the backup sub-directory
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupName = "$($File.Name)_$(Get-Date -Format 'yyyyMMddHHmmss')" # Full original name + timestamp
$BackupFile = Join-Path -Path $BackupDir -ChildPath $BackupName
Move-Item -Path $OriginalPath -Destination $BackupFile

# Move temp file to its new final name
# e.g., "temp_recode_MyVideo.mkv.mp4" -> "MyVideo.mkv.mp4"
$NewFinalName = "$($UniqueBaseName)$($using:OutputExtension)"
$NewFinalPath = Join-Path -Path $File.DirectoryName -ChildPath $NewFinalName
Move-Item -Path $TempOutputPath -Destination $NewFinalPath

$SpaceSaved = $OriginalSize - $NewSize
$SavedMB = [Math]::Round($SpaceSaved / 1MB, 2)
$Status = "SUCCESS: Kept new file (from $Codec). Saved $SavedMB MB"

} else {
# FAILURE: New file is larger. Keep original.
$WastedMB = [Math]::Round(($NewSize - $OriginalSize) / 1MB, 2)
$Status = "KEPT OLD: New file was larger (from $Codec) by $WastedMB MB"

# Create the backup sub-directory and move the (larger) temp file
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$FailedName = "$($UniqueBaseName)-LARGER-$(Get-Date -Format 'yyyyMMddHHmmss')$($using:OutputExtension)"
$BackupFile = Join-Path -Path $BackupDir -ChildPath $FailedName
Move-Item -Path $TempOutputPath -Destination $BackupFile -ErrorAction SilentlyContinue
}
}
}
} catch {
$Status = "ERROR: $($_.Exception.Message.Split([System.Environment]::NewLine)[0])"
}

# Return the result object to the main thread
return [PSCustomObject]@{
File = $OriginalPath
Result = $Status
Saved = $SpaceSaved
}

} -ThrottleLimit $ThrottleLimit | ForEach-Object {
# --- 6. PASS 3: PROGRESS & LOGGING (MAIN THREAD) ---
$script:ProcessedCount++
$script:TotalSpaceSaved += $_.Saved

$Percent = ($script:ProcessedCount / $TotalCount) * 100
$Elapsed = $Stopwatch.Elapsed.ToString('hh\:mm\:ss')

# Estimate remaining time
$EstTotal = [timespan]::FromTicks($Stopwatch.Elapsed.Ticks * ($TotalCount / $script:ProcessedCount))
$EstRemain = $EstTotal - $Stopwatch.Elapsed
$EstRemainString = $EstRemain.ToString('hh\:mm\:ss')

$SavedGB = [Math]::Round($script:TotalSpaceSaved / 1GB, 2)
$ProgressMessage = "Processed {0} of {1} files. Total Saved: {2} GB (Elapsed: {3} | Est. Remain: {4})" -f $script:ProcessedCount, $TotalCount, $SavedGB, $Elapsed, $EstRemainString

Write-Progress -Activity $ActivityMessage -Status $ProgressMessage -CurrentOperation $_.File -PercentComplete $Percent

# Write the result to the log file
$LogEntry = "[{0}] - {1} - {2}" -f (Get-Date), $_.Result, $_.File
$LogEntry | Add-Content -Path $LogFile
}

$Stopwatch.Stop()
Write-Progress -Activity $ActivityMessage -Completed
Write-Host "🎉 Encoding finished! Total time: $($Stopwatch.Elapsed.ToString('hh\:mm\:ss'))"

# --- 7. PASS 4: FINAL CLEANUP (NO RESTORE) ---
Write-Host "🧼 Pass 4: Running final temp file cleanup..."
$OrphanedFiles = Get-ChildItem -Path $SourcePath -Recurse -File -Filter "$($TempPrefix)*"
foreach ($TempFile in $OrphanedFiles) {
Write-Warning " Deleting leftover orphan: $($TempFile.FullName)"
Remove-Item $TempFile.FullName -ErrorAction SilentlyContinue
$LogEntry = "[{0}] - CLEANUP 2 - Deleted orphan file: {1}" -f (Get-Date), $TempFile.FullName
$LogEntry | Add-Content -Path $LogFile
}
Write-Host "✅ Final cleanup finished."

# --- 8. PASS 5: PRETTY NAMING ---
Write-Host "💅 Pass 5: Running pretty naming cleanup..."
$RenameCounter = 0
# We need to get all the uniquely-named files that were successfully created.
# e.g., files like "MyVideo.mkv.mp4"
$FilesToRename = Get-ChildItem -Path $SourcePath -Recurse -File -Filter "*.*$($OutputExtension)"

foreach ($File in $FilesToRename) {
    # Extract the original extension and the base name
    # e.g., "MyVideo.mkv.mp4" -> $OriginalExtension = ".mkv", $BaseName = "MyVideo"
    $OriginalExtension = [System.IO.Path]::GetExtension($File.BaseName)
    $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($File.BaseName)

    # Construct the "pretty" new name
    # e.g., "MyVideo.mp4"
    $PrettyName = $BaseName + $OutputExtension
    $PrettyPath = Join-Path -Path $File.DirectoryName -ChildPath $PrettyName

    # --- SAFETY CHECK ---
    # Only rename if the pretty name doesn't already exist.
    if (-not (Test-Path $PrettyPath)) {
        try {
            Rename-Item -Path $File.FullName -NewName $PrettyName -ErrorAction Stop
            $LogEntry = "[{0}] - RENAME - '{1}' to '{2}'" -f (Get-Date), $File.Name, $PrettyName
            $LogEntry | Add-Content -Path $LogFile
            $RenameCounter++
        } catch {
            $LogEntry = "[{0}] - RENAME FAILED - Could not rename '{1}'. Reason: {2}" -f (Get-Date), $File.Name, $_.Exception.Message
            $LogEntry | Add-Content -Path $LogFile
        }
    } else {
        # A file with the pretty name already exists, likely from a parallel encode of a duplicate name (e.g. movie.mkv, movie.mov).
        # We leave the unique name in place for manual review.
        $LogEntry = "[{0}] - RENAME SKIPPED - A file named '{1}' already exists. Cannot rename '{2}'." -f (Get-Date), $PrettyName, $File.Name
        $LogEntry | Add-Content -Path $LogFile
    }
}
Write-Host "✅ Pretty naming finished. $RenameCounter files renamed."

# --- Final summary ---
$TotalSavedGB = [Math]::Round($script:TotalSpaceSaved / 1GB, 2)
Write-Host "🎉 All done!"
Write-Host "Total space saved: $TotalSavedGB GB."
Write-Host "Full log saved to $LogFile"
