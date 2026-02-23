# Claude Code Notification Hook Script (Windows PowerShell)

$json = ($input | Out-String) | ConvertFrom-Json -ErrorAction SilentlyContinue
$hookEvent = $json.hook_event_name
$message = switch ($hookEvent) {
    "SessionStart"  { "Session started" }
    "SessionEnd"    { "Session completed" }
    "Stop"          { "Needs your input!" }
    "Notification"       { $json.message }
    "PermissionRequest"  { "Permission needed!" }
    default              { "$hookEvent : $($json.message)" }
}

# Windows Toast Notification
$template = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::GetTemplateContent(
    [Windows.UI.Notifications.ToastTemplateType, Windows.UI.Notifications, ContentType = WindowsRuntime]::ToastText02
)
$template.SelectSingleNode('//text[@id="1"]').InnerText = "Claude Code"
$template.SelectSingleNode('//text[@id="2"]').InnerText = $message
$appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($template)