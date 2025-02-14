local function DefaultCrew()
    local defaultCrewGrade = {
        none = {
            rank = 0,
            name = 'none',
            label = 'None',
            salary = 0,
            permission = {},
            whitelisted = false,
        }
    }

    local defaultCrew = HandleCrew(
        'none',
        'None',
        'none',
        0,
        false,
        defaultCrewGrade
    )

    ABT.Crews['none'] = defaultCrew
end

local function FetchCrew()
    local fetchQuery = [[
        SELECT c.*, cg.*
        FROM crews c
        LEFT JOIN crew_grades cg ON c.crew_name = cg.crew_name
    ]]

    MySQL.Async.fetchAll(fetchQuery, {}, function(results)
        if not results or #results == 0 then
            ABT.Print.Log(3, 'No crews or grades found. Only default crew will be used.')
            return
        end

        local crews = {}

        for _, row in ipairs(results) do
            if not crews[row.crew_name] then
                crews[row.crew_name] = {
                    label = row.crew_label,
                    owner = row.owner_identifier,
                    money = row.crew_money,
                    whitelisted = row.is_crew_whitelisted,
                    grades = {}
                }
            end

            if row.crew_grade_name then
                crews[row.crew_name].grades[row.crew_grade_name] = {
                    rank = row.crew_grade,
                    name = row.crew_grade_name,
                    label = row.crew_grade_label,
                    salary = row.crew_grade_salary,
                    permission = json.decode(row.crew_grade_permissions or '{}'),
                    whitelisted = row.is_crew_grade_whitelisted
                }
            end
        end

        for name, data in pairs(crews) do
            if not ABT.Crews[name] then
                local crew = HandleCrew(
                    name,
                    data.label,
                    data.owner,
                    data.money,
                    data.whitelisted,
                    data.grades
                )

                ABT.Crews[name] = crew
                ABT.Print.Log(5, ('Crew %s has been loaded.'):format(name))

                if not next(data.grades) then
                    ABT.Print.Log(3, ('Crew %s has no grades associated. Check database.'):format(name))
                end
            else
                ABT.Print.Log(3, ('Crew %s already exists and will not be loaded.'):format(name))
            end
        end

        ABT.Print.Log(5, 'Crews and grades have been successfully loaded:', ABT.Crews)
    end)
end

--- Get a crew object from its name
---@param name string The crew's name
---@return CrewObject The crew object
function ABT.GetCrewFromName(name)
    return ABT.Crews[name]
end

function ABT.DoesCrewExist(name, grade)
    local crew = ABT.Crews[name]
    if not crew then
        return false
    end

    local grades = crew.crewGrades.getAllGrades()
    if not grades[grade] then
        return false
    end

    return true
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    DefaultCrew()
    FetchCrew()
end)