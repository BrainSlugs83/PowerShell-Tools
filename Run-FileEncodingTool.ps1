<# MIT License

Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. #>

$btnDecode_Click = {

    Write-log "Decode Selected.";
    $infn = OpenFileDialog -title "Select a file to Decode:" -filters $TextFilesFilter;
    if ([string]::IsNullOrWhiteSpace($infn)) {
        Write-Log("No file to decode selected; aborting.");
        Write-Log;
        return;
    }
    
    Write-Log("File to Decode: " + $infn);

    $suggestedFileName = "";
    $expectedHash = "";
    $expectedLength = 0;
    foreach ($line in (cat $infn | ? { (-not [string]::IsNullOrWhiteSpace($_)) -and $_.Trim().StartsWith("#") } | Select -First 3)) {
        if ($line.Substring(1).Trim().StartsWith("Input File Name:")) {
            $suggestedFileName = $line.Substring($line.IndexOf(":") + 1).Trim();
            Write-Log("Original FileName: " + $suggestedFileName);
        }

        if ($line.Substring(1).Trim().StartsWith("Input Length:")) {
            $expectedLength = [int]::Parse($line.Substring($line.IndexOf(":") + 1).Trim());
            Write-Log("Expected Output Length: " + $expectedLength.ToString("###,###,###,###"));
        }

        if ($line.Substring(1).Trim().StartsWith("MD5:")) {
            $expectedHash = $line.Substring($line.IndexOf(":") + 1).Trim();
            Write-Log("Expected MD5 Hash: " + $expectedHash);
        }
    }

    $outfn = SaveFileDialog -title "Saving Decoded File As:" -filters $AllFilesFilter -suggestedFileName $suggestedFileName;
    if ([string]::IsNullOrWhiteSpace($outfn)) {
        Write-Log("No save as file selected; aborting.");
        Write-Log;
        return;
    }

    Write-Log("Streaming output to file: " + $outfn)

    $append = $false;
    foreach ($line in (cat $infn | ? { (-not [string]::IsNullOrWhiteSpace($_)) -and (-not $_.Trim().StartsWith("#")) })) {
        $bytes = [System.Convert]::FromBase64String($line.Trim());

        WriteBytes -filePath $outfn -bytes $bytes -append $append;
        $append = $true;
    }

    $actualLength = (gci $outfn).Length;
    $actualHash = (Get-FileHash $outfn -Algorithm MD5).Hash;

    Write-Log("Actual Length: " + $actualLength.ToString("###,###,###,###"));
    Write-Log("Actual MD5 Hash: " + $actualHash);

    if ($actualLength -ne $expectedLength -and $expectedLength -gt 0)
    {
        Write-Log("***WARNING***: Actual length of output file does not match the expected length of " + $expectedLength.ToString("###,###,###,###") + "!");
    }

    if ($actualHash -ne $expectedHash -and (-not [string]::IsNullOrWhiteSpace($expectedHash)))
    {
        Write-Log("***WARNING***: Actual hash of output file does not match the expected hash of " + $expectedHash + "!");
    }

    if ($actualLength -eq $expectedLength -and $actualHash -eq $expectedHash)
    {
        Write-Log("Length and Hash Validation passed!");
        Write-Log("Operation Successful!");
    }
    Write-Log;
}

$btnEncode_Click = {
    Write-Log("Encode Selected.");
    $fn = OpenFileDialog -title "Select a file to Encode:" -filters $AllFilesFilter;
    if ([string]::IsNullOrWhiteSpace($fn)) {
        Write-Log("No file to encode selected; aborting.");
        Write-Log;
        return;
    }
    
    Write-Log("File to Encode: " + $fn);
    

    $outfn = SaveFileDialog -title "Saving Encoded File As:" -filters $TextFilesFilter
    if ([string]::IsNullOrWhiteSpace($outfn)) {
        Write-Log("No save as file selected; aborting.");
        Write-Log;
        return;
    }
    
    Write-Log("Saving Encoded File As: " + $outfn);
    Write-Log("Streaming text output . . .");
    
    ("# Input File Name: " + (gci $fn | % { $_.Name })) | Out-File -FilePath $outfn -Encoding UTF8 -Force;
    ("# Input Length: " + (gci $fn | % { $_.Length })) | Out-File -FilePath $outfn -Encoding UTF8 -Force -Append;
    ("# MD5: " + (Get-FileHash $fn -Algorithm MD5).Hash) | Out-File -FilePath $outfn -Encoding UTF8 -Force -Append;

    $length = 0
    $outLen = 0;
    foreach($row in (Read-ChunkedFile -FilePath $fn)) {
        $b64 = [System.Convert]::ToBase64String($row);

        $b64 | Out-File -FilePath $outfn -Encoding UTF8 -Force -Append;

        $length += $row.Length;
        $outLen += $b64.Length;
    }

    Write-Log("Raw Input read: " + $length.ToString("###,###,###,###"));
    Write-Log("Encoded Output written: " + $outLen.ToString("###,###,###,###"));
    Write-Log("Operation Successful!");
    Write-Log;
}

function OpenFileDialog($title, $filters) {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $title;
    $openFileDialog.Filter = $filters
    $result = $openFileDialog.ShowDialog();

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.FileName;
    }
    return $null;
}

function SaveFileDialog($title, $filters, $suggestedFileName) {
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = $title;
    $saveFileDialog.Filter = $filters;
    $saveFileDialog.OverwritePrompt = $true;

    if (-not [string]::IsNullOrWhiteSpace($suggestedFileName)) {
        $saveFileDialog.FileName = $suggestedFileName;
        $ext = [System.IO.Path]::GetExtension($suggestedFileName);
        if (-not [string]::IsNullOrWhiteSpace($ext)) {
            if (-not $saveFileDialog.Filter.ToUpperInvariant().Contains($ext.ToUpperInvariant())) {
                $saveFileDialog.Filter = ("*" + $ext + "|*" + $ext + "|") + $saveFileDialog.Filter;
            }
        }
    }

    $result = $saveFileDialog.ShowDialog();
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $saveFileDialog.FileName;
    }
    return $null;
}

function Write-Log($text) {
    if ($null -eq $text) { $text = ""; } else { 
        $text = $text.ToString();
        $text = ("[" + [DateTime]::Now.ToString("yyyy-MM-dd hh:mm:ss tt") + "] " + $text.TrimEnd());
    }

    $txtLog.AppendText($text + "`r`n");
    Write-Host $text;
}

function WriteBytes($filePath, $bytes, $append)
{
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($append)
        {
            Add-Content -Path $outfn -Value $bytes -NoNewLine -Force -AsByteStream;    
        }
        else
        {
            Set-Content -Path $outfn -Value $bytes -NoNewLine -Force -AsByteStream;
        }
    }
    else {
        if ($append)
        {
            Add-Content -Path $outfn -Value $bytes -NoNewLine -Force -Encoding Byte;
        }
        else {
            Set-Content -Path $outfn -Value $bytes -NoNewLine -Force -Encoding Byte;
        }
    }
}

function Read-ChunkedFile {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [int]$ChunkSize = 1MB
    )

    # Find the file from the current context and not the app domain.
    $FilePath = (gci $FilePath).FullName;

    $fs = $null;
    try {
        $fs = [System.IO.File]::OpenRead($FilePath);
        $buffer = New-Object byte[] $ChunkSize

        while (($bytesRead = $fs.Read($buffer, 0, $ChunkSize)) -gt 0) {
            Write-Host $bytesRead;
            if ($bytesRead -lt $ChunkSize) {
                # Trim buffer for final partial read
                Write-Output $buffer[0..($bytesRead - 1)] -NoEnumerate;
            } else {
                Write-Output $buffer.Clone() -NoEnumerate;
            }
        }
    }
    finally {
        if ($fs -ne $null)
        {
            $fs.Dispose()
        }
    }
}

$AllFilesFilter = "All files (*.*)|*.*";
$TextFilesFilter = ("Text files (*.txt)|*.txt|" + $AllFilesFilter);

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.IO

$frmMain = New-Object -TypeName System.Windows.Forms.Form
[System.Windows.Forms.Button]$btnEncode = $null
[System.Windows.Forms.Button]$btnDecode = $null
[System.Windows.Forms.TextBox]$txtLog = $null
function InitializeComponent
{
$btnEncode = (New-Object -TypeName System.Windows.Forms.Button)
$btnDecode = (New-Object -TypeName System.Windows.Forms.Button)
$txtLog = (New-Object -TypeName System.Windows.Forms.TextBox)
$frmMain.SuspendLayout()
#
#btnEncode
#
$btnEncode.Dock = [System.Windows.Forms.DockStyle]::Top
$btnEncode.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0,[System.Int32]0))
$btnEncode.Name = [System.String]'btnEncode'
$btnEncode.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]728,[System.Int32]23))
$btnEncode.TabIndex = [System.Int32]0
$btnEncode.Text = [System.String]'Encode File'
$btnEncode.UseVisualStyleBackColor = $true
$btnEncode.add_Click($btnEncode_Click)
#
#btnDecode
#
$btnDecode.Dock = [System.Windows.Forms.DockStyle]::Top
$btnDecode.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0,[System.Int32]23))
$btnDecode.Name = [System.String]'btnDecode'
$btnDecode.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]728,[System.Int32]27))
$btnDecode.TabIndex = [System.Int32]1
$btnDecode.Text = [System.String]'Decode File'
$btnDecode.UseVisualStyleBackColor = $true
$btnDecode.add_Click($btnDecode_Click)
#
#txtLog
#
$txtLog.AcceptsReturn = $true
$txtLog.AcceptsTab = $true
$txtLog.Dock = [System.Windows.Forms.DockStyle]::Fill
$txtLog.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]0,[System.Int32]50))
$txtLog.Multiline = $true
$txtLog.Name = [System.String]'txtLog'
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txtLog.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]728,[System.Int32]211))
$txtLog.TabIndex = [System.Int32]2
#
#frmMain
#
$frmMain.ClientSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]728,[System.Int32]261))
$frmMain.Controls.Add($txtLog)
$frmMain.Controls.Add($btnDecode)
$frmMain.Controls.Add($btnEncode)
$frmMain.Text = [System.String]'File-to-Text Encoding / Decoding Tool'
$frmMain.ResumeLayout($false)
$frmMain.PerformLayout()
Add-Member -InputObject $frmMain -Name btnEncode -Value $btnEncode -MemberType NoteProperty
Add-Member -InputObject $frmMain -Name btnDecode -Value $btnDecode -MemberType NoteProperty
Add-Member -InputObject $frmMain -Name txtLog -Value $txtLog -MemberType NoteProperty
}
. InitializeComponent


[void]$frmMain.ShowDialog()


