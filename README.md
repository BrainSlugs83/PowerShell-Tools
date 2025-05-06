# PowerShell-Tools
Tools for PowerShell

## File Encoding / Decoding Tool
This tool allows you to convert a binary file between Base64 Text and Raw Binary; it also includes some things like MD5 Hash Checking and Length Checking, to verify the output file is going to be a binary match with the input.

This is useful for when you have access to Copy & Paste Text into a remote VM, (e.g. into Notepad) but you do not have the ability to copy files directly (e.g. Excel files, .zip files, etc.).

The only requirement is PowerShell 5 or greater.  

**Note:** Please note, that for very large files, this may cause a temporary hang if you attempt to copy & paste the entire text file all at once.  I do not recommend using this method for files over 50 MB in size, unless you have no other choice.

### How to Launch the Tool?
#### Option 1: If GitHub is NOT BLOCKED:

1. Open PowerShell 5 or later on the target machine
2. Copy the following command:
```PowerShell
& ([scriptblock]::Create((irm "https://raw.githubusercontent.com/BrainSlugs83/PowerShell-Tools/refs/heads/main/Run-FileEncodingTool.ps1")))
```
3. Paste the command into the PowerShell prompt and press <ENTER>, the tool should open.
  
#### Option 2: If GitHub is BLOCKED:
1. On a machine where GitHub is not blocked (e.g. your local computer):
2. Navigate to [Run-FileEncodingTool.ps1](https://raw.githubusercontent.com/BrainSlugs83/PowerShell-Tools/refs/heads/main/Run-FileEncodingTool.ps1)
3. Select All (CTRL+A)
4. Copy (CTRL+C)
5. In your remote VM, where GitHub is blocked, open PowerShell 5 or later.
6. Paste (CTRL+V)
7. Select "Paste Anyway" if the option is presented.
8. If neccessary, press <ENTER>, the tool should open.
 
### Usage:
#### To convert a Binary File to Text: (e.g. .xlsx, .zip, or .exe, .etc to .txt)
1. Run the tool on the machine where the input binary file resides (e.g. your local machine).
2. Select "Encode File".
3. In the Open Dialog Box, select the raw binary file that you want to convert into text.
4. In the Save File Dialog Box, select the text file to output to.
5. Wait for the process to complete successfully.
6. Once completed, navigate to the text file, and open it in your favorite text editor.
7. Once the file is open in a text editor, Select All (CTRL + A).
8. Copy (CTRL+C).
9. In your remote VM, create a new text file using your text editor.
10. Paste the text (CTRL+V) into the remote text editor.
11. Save the file.

#### To Convert a Text File back to a usable Binary File: (e.g. .txt to .xlsx, .zip, or .exe, etc.)
1. Run the tool on the machine where the input text file resides (e.g. the foreign machine where you saved the text file to in the previous steps).
2. Select "Decode File".
3. In the Open File Dialog Box, select the raw text file that you want to convert back into a binary.
4. In the Save File Dialog Box, select the output file that you want to recreate.
5. Wait for the process to complete successfully.
6. You should see some messages in the log regarding the file size ("Length") and the Hash ("MD5 Hash").  There should either be a message indicating the file was recreated successfully, or a warning that the output file does not match the intended file size ("Length") or Hash ("MD5 Hash"). -- If you get a warning, it probably means you did not select the entire file in the original text file.
   
  
