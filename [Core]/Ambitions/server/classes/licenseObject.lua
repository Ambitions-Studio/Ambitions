--- Class for License Object
function CreateAmberLicense()
    ---@class LicenseObject
    ---@field licenses table Table of licenses
    local self = {}
    self.licenses = {}

    --- Load all licenses from the database and store them in cache
    function self.loadLicenses()
        local query = "SELECT * FROM licenses"
        MySQL.Async.fetchAll(query, {}, function(results)
            if results then
                for _, row in ipairs(results) do
                    self.licenses[row.license_type] = {
                        type = row.license_type,
                        label = row.license_label
                    }
                end
                ABT.Print.Log(5, ("Loaded %d licenses into cache."):format(#results))
            else
                ABT.Print.Log(3, "No licenses found in database.")
            end
        end)
    end

    ---@return table licenses The table of all licenses
    function self.getAllLicenses()
        return self.licenses
    end

    ---@param licenseType string The type of the license
    ---@return table | nil The license object or nil if not found
    function self.getLicense(licenseType)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        if not self.licenses[licenseType] then
            ABT.Print.Log(3, ("License '%s' does not exist in cache."):format(licenseType))
            return nil
        end

        return self.licenses[licenseType]
    end

    ---@param licenseType string The type of the license
    ---@param licenseLabel string The label of the license
    function self.addLicense(licenseType, licenseLabel)
        assert(type(licenseType) == 'string', 'The license type must be a string.')
        assert(type(licenseLabel) == 'string', 'The license label must be a string.')

        if self.licenses[licenseType] then
            ABT.Print.Log(3, ("License '%s' already exists in cache."):format(licenseType))
            return
        end

        MySQL.Async.execute(
            "INSERT INTO licenses (license_type, license_label) VALUES (?, ?) ON DUPLICATE KEY UPDATE license_label = VALUES(license_label)",
            { licenseType, licenseLabel },
            function(rowsAffected)
                if rowsAffected > 0 then
                    self.licenses[licenseType] = {
                        type = licenseType,
                        label = licenseLabel
                    }
                    ABT.Print.Log(5, ("License '%s' added successfully."):format(licenseType))
                else
                    ABT.Print.Log(3, ("Failed to add license '%s' to the database."):format(licenseType))
                end
            end
        )
    end

    ---@param licenseType string The type of the license
    function self.removeLicense(licenseType)
        assert(type(licenseType) == 'string', 'The license type must be a string.')

        if not self.licenses[licenseType] then
            ABT.Print.Log(3, ("License '%s' does not exist in cache."):format(licenseType))
            return
        end

        MySQL.Async.execute("DELETE FROM licenses WHERE license_type = ?", { licenseType }, function(rowsAffected)
            if rowsAffected > 0 then
                self.licenses[licenseType] = nil
                ABT.Print.Log(5, ("License '%s' removed successfully."):format(licenseType))
            else
                ABT.Print.Log(3, ("Failed to remove license '%s' from the database."):format(licenseType))
            end
        end)
    end

    return self
end

ABT.Licenses = CreateAmberLicense()

--- Load licenses into cache when the resource starts
AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    ABT.Licenses.loadLicenses()
end)