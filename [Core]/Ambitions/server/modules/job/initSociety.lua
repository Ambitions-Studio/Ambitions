local function DefaultSociety()
    local defaultSocietyGrade = {
        unemployed = {
            rank = 0,
            name = 'unemployed',
            label = 'Unemployed',
            salary = 0,
            permission = {},
            whitelisted = false,
        }
    }
    local defaultSociety = HandleSociety(
        'unemployed',
        'Unemployed',
        'none',
        nil,
        0,
        false,
        defaultSocietyGrade
    )

    ABT.Societies['unemployed'] = defaultSociety
end

local function FetchSociety()
    local fetchQuery = [[
        SELECT s.*, sg.*
        FROM society s
        LEFT JOIN society_grades sg ON s.society_name = sg.society_name
    ]]

    MySQL.Async.fetchAll(fetchQuery, {}, function(results)
        if not results or #results == 0 then
            ABT.Print.Log(3, 'No societies or grades found. Only default society will be used.')
            return
        end

        local societies = {}

        for _, row in ipairs(results) do
            if not societies[row.society_name] then
                societies[row.society_name] = {
                    label = row.society_label,
                    owner = row.owner_identifier,
                    iban = row.society_iban,
                    money = row.society_money,
                    whitelisted = row.is_society_whitelisted,
                    grades = {}
                }
            end

            if row.society_grade_name then
                societies[row.society_name].grades[row.society_grade_name] = {
                    rank = row.society_grade,
                    name = row.society_grade_name,
                    label = row.society_grade_label,
                    salary = row.society_grade_salary,
                    permission = json.decode(row.society_grade_permissions or '{}'),
                    whitelisted = row.is_society_grade_whitelisted
                }
            end
        end

        for societyName, societyData in pairs(societies) do
            if not ABT.Societies[societyName] then
                local societyInstance = HandleSociety(
                    societyName,
                    societyData.label,
                    societyData.owner,
                    societyData.iban,
                    societyData.money,
                    societyData.whitelisted,
                    societyData.grades
                )
                ABT.Societies[societyName] = societyInstance
                ABT.Print.Log(5, ("Society '%s' initialized."):format(societyName))
            else
                ABT.Print.Log(3, ("Society '%s' already exists. Skipping initialization."):format(societyName))
            end
        end

        ABT.Print.Log(5, "Societies and grades successfully initialized:", ABT.Societies)
    end)
end

--- Get a society object from its name
---@param societyName string The name of the society
---@return SocietyObject
function ABT.GetSocietyFromName(societyName)
    return ABT.Societies[societyName]
end

--- Check if a society and its grade exist.
---@param jobName string The name of the society (job).
---@param jobGrade string The name of the grade.
---@return boolean True if the society and grade exist, false otherwise.
function ABT.DoesSocietyExist(jobName, jobGrade)
    local society = ABT.Societies[jobName]
    if not society then
        return false
    end

    local grades = society.societyGrades.getAllGrades()
    if not grades[jobGrade] then
        return false
    end

    return true
end


AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    DefaultSociety()
    FetchSociety()
end)
