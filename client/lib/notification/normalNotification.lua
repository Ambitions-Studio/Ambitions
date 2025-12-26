--- Displays a notification to the player using the Ambitions-Notify system
---@param notificationTitle string The title of the notification
---@param notificationMessage string|false The description/message of the notification, or false for no description
---@param notificationType string The type of notification: 'success', 'error', 'info', 'warning', or 'debug'
---@param notificationDuration number The duration in milliseconds the notification should be displayed
---@param notificationPosition string The position on screen: 'top-left', 'top-center', 'top-right', 'middle-left', 'middle-center', 'middle-right', 'bottom-left', 'bottom-center', 'bottom-right'
---@return void
function amb.ShowNotification(notificationTitle, notificationMessage, notificationType, notificationDuration, notificationPosition)
    if GetResourceState('Ambitions-Notify') ~= 'missing' then
        return exports['Ambitions-Notify']:Notify(notificationTitle, notificationMessage, notificationType, notificationDuration, notificationPosition)
    end
end

RegisterNetEvent('ambitions:client:showNotification', function(notificationTitle, notificationMessage, notificationType, notificationDuration, notificationPosition)
    amb.ShowNotification(notificationTitle, notificationMessage, notificationType, notificationDuration, notificationPosition)
end)
