--- Class for crew grade Object
---@param grades table Grades table
function HandleCrewGrade(grades)
    ---@class CrewGradeObject
    ---@field grades table Grades table
    local self = {}
    self.grades = grades or {}

    --- Validate the existence of a grade
    ---@param gradeName string The name of the grade
    local function validateGrade(gradeName)
        assert(type(gradeName) == 'string', 'The grade name must be a string.')
        assert(self.grades[gradeName], ("The grade '%s' does not exist."):format(gradeName))
    end

    ---@return table All grades of the crew
    function self.getAllGrades()
        return self.grades
    end

    ---@param gradeName string The name of the grade
    ---@return table The grade information
    function self.getGrade(gradeName)
        validateGrade(gradeName)
        return self.grades[gradeName]
    end

    ---@param gradeName string The name of the grade
    ---@param gradeLabel string The label of the grade
    ---@param gradeSalary number The salary of the grade
    ---@param gradePermission table The permissions of the grade
    ---@param gradeWhitelisted boolean Whether the grade is whitelisted
    function self.addGrade(gradeName, gradeLabel, gradeSalary, gradePermission, gradeWhitelisted)
        assert(type(gradeName) == 'string', 'The grade name must be a string.')
        assert(type(gradeLabel) == 'string', 'The grade label must be a string.')
        assert(type(gradeSalary) == 'number', 'The grade salary must be a number.')
        assert(type(gradePermission) == 'table', 'The grade permissions must be a table.')
        assert(type(gradeWhitelisted) == 'boolean', 'The grade whitelisted status must be a boolean.')
        assert(not self.grades[gradeName], ("A grade with the name '%s' already exists."):format(gradeName))

        local maxRank = 0
        for _, grade in pairs(self.grades) do
            if grade.rank > maxRank then
                maxRank = grade.rank
            end
        end
        local newRank = maxRank + 1

        self.grades[gradeName] = {
            rank = newRank,
            name = gradeName,
            label = gradeLabel,
            salary = gradeSalary,
            permission = gradePermission,
            whitelisted = gradeWhitelisted
        }
    end

    ---@param gradeName string The name of the grade
    function self.removeGrade(gradeName)
        validateGrade(gradeName)
        self.grades[gradeName] = nil
    end

    ---@param gradeName string The name of the grade
    ---@return number The rank of the grade
    function self.getRank(gradeName)
        validateGrade(gradeName)
        return self.grades[gradeName].rank
    end

    ---@param gradeName string The name of the grade
    ---@return number The salary of the grade
    function self.getSalary(gradeName)
        validateGrade(gradeName)
        return self.grades[gradeName].salary
    end

    ---@param gradeName string The name of the grade
    ---@param gradeSalary number The salary of the grade
    function self.setSalary(gradeName, gradeSalary)
        validateGrade(gradeName)
        assert(type(gradeSalary) == 'number', 'The grade salary must be a number.')
        self.grades[gradeName].salary = gradeSalary
    end

    ---@param gradeName string The name of the grade
    ---@param permission string The permission to add
    function self.addPermission(gradeName, permission)
        validateGrade(gradeName)
        assert(type(permission) == 'string', 'The permission must be a string.')

        local permissions = self.grades[gradeName].permission

        for _, perm in ipairs(permissions) do
            if perm == permission then
                return
            end
        end

        table.insert(permissions, permission)
    end


    ---@param gradeName string The name of the grade
    ---@param permission string The permission to remove
    function self.removePermission(gradeName, permission)
        validateGrade(gradeName)
        assert(type(permission) == 'string', 'The permission must be a string.')

        local permissions = self.grades[gradeName].permission
        for i, perm in ipairs(permissions) do
            if perm == permission then
                table.remove(permissions, i)
                return
            end
        end
        ABT.Print.Log(3, ("The permission '%s' does not exist for the grade '%s'."):format(permission, gradeName))
    end

    ---@param gradeName string The name of the grade
    ---@return boolean Whether the grade is whitelisted
    function self.getGradeWhitelisted(gradeName)
        validateGrade(gradeName)
        return self.grades[gradeName].whitelisted
    end

    ---@param gradeName string The name of the grade
    ---@param whitelisted boolean The new whitelisted status
    function self.setGradeWhitelisted(gradeName, whitelisted)
        validateGrade(gradeName)
        assert(type(whitelisted) == 'boolean', 'The whitelisted status must be a boolean.')
        self.grades[gradeName].whitelisted = whitelisted
    end

    return self
end