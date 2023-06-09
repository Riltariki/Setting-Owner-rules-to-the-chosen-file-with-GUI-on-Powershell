# Load Microsoft.PowerShell.Management module
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Run Application as Service"
$form.Size = New-Object System.Drawing.Size(400,250)
$form.StartPosition = "CenterScreen"

# Create buttons and text fields on the form
$button_file_path = New-Object System.Windows.Forms.Button
$button_file_path.Location = New-Object System.Drawing.Point(30, 120)
$button_file_path.Size = New-Object System.Drawing.Size(150,30)
$button_file_path.Text = "Select Application"
$form.Controls.Add($button_file_path)

$name_entry_field = New-Object System.Windows.Forms.Label
$name_entry_field.Location = New-Object System.Drawing.Point(30,20)
$name_entry_field.Size = New-Object System.Drawing.Size(200,20)
$name_entry_field.Text = "Application Path: "
$form.Controls.Add($name_entry_field)

$entry_field = New-Object System.Windows.Forms.TextBox
$entry_field.Location = New-Object System.Drawing.Point(30,40)
$entry_field.Size = New-Object System.Drawing.Size(320,20)
$form.Controls.Add($entry_field)

$label2 = New-Object System.Windows.Forms.Label
$label2.Text = "Select User"
$label2.AutoSize = $true
$label2.Location = New-Object System.Drawing.Point(30, 70)
$form.Controls.Add($label2)

# Create ComboBox for selecting the user
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(30, 90)
$comboBox.Size = New-Object System.Drawing.Size(200, 25)
$comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$form.Controls.Add($comboBox)

# Get the list of users
$users = Get-LocalUser | Select-Object Name

# Add items to ComboBox
foreach ($user in $users) {
    $comboBox.Items.Add($user.Name)
}

$button = New-Object System.Windows.Forms.Button
$button.Location = New-Object System.Drawing.Point(230, 170)
$button.Size = New-Object System.Drawing.Size(150, 30)
$button.Text = "Grant Owner Permissions"
$button.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#b8e986")
$form.Controls.Add($button)
$button.Add_Click({
    $selectedDisk = $entry_field.Text
    $selectedUser = $comboBox.SelectedItem

    # Actions to perform when a disk is selected
    Write-Host "Selected disk: $selectedDisk"
    $pathtodisk = $selectedDisk
    $old_acl = Get-ACL $pathtodisk
    $dir = Get-ChildItem $pathtodisk
    $user_sid = New-Object System.Security.Principal.Ntaccount($selectedUser)
    $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule($selectedUser, "FullControl, TakeOwnership, ChangePermissions", "Allow")
    $old_acl.SetAccessRule($Rule)
    $old_acl | Set-Acl $pathtodisk
    $old_acl.SetOwner($user_sid)
    $old_acl | Set-Acl $pathtodisk

    if ($dir.FullName -eq $pathtodisk)
    {
        $acl = Get-Acl $pathtodisk
        $acl.SetAccessRule($Rule)
        $acl | Set-Acl $pathtodisk
        $acl.SetOwner($user_sid)
        $acl | Set-Acl $pathtodisk
    }
    else
    {
        # Iterate through all files in the directory
        foreach ($dirin in $dir)
        {
            $acl = Get-Acl ($pathtodisk + $dirin.Name)
            $acl.SetAccessRule($Rule)
            $acl | Set-Acl ($pathtodisk + $dirin.Name)
            $acl.SetOwner($user_sid)
            $acl | Set-Acl ($pathtodisk + $dirin.Name)
        }
    }
    Write-Host "New owner: " (Get-ACL $pathtodisk).Owner
})

# Function to execute when the "Select Application" button is clicked
function button_file_path_func {
    $open_file_path_okno = New-Object System.Windows.Forms.OpenFileDialog
    $open_file_path_okno.Filter = "All files (*.*)|*.*"
    $open_file_path_okno.FilterIndex = 0
    $open_file_path_okno.Multiselect = $false
    $open_file_path_okno.ShowDialog() | Out-Null

    if ($open_file_path_okno.FileName) {
        $entry_field.Text = $open_file_path_okno.FileName
    }
}

# Assign functions to button click events
$button_file_path.Add_Click({button_file_path_func})

# Display the form
$form.ShowDialog() | Out-Null