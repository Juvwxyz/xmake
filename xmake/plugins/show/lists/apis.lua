--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        apis.lua
--

-- imports
import("core.project.config")
import("core.project.rule")
import("core.project.target")
import("core.project.project")
import("core.project.option")
import("core.package.package")
import("core.sandbox.sandbox")
import("core.sandbox.module")
import("core.tool.toolchain")
import(".showlist")

function _is_callable(func)
    if type(func) == "function" then
        return true
    elseif type(func) == "table" then
        local meta = debug.getmetatable(func)
        if meta and meta.__call then
            return true
        end
    end
end

-- get project scope apis
function project_scope_apis()
    local result = {}
    for _, names in pairs(project.apis()) do
        for _, name in ipairs(names) do
            if type(name) == "table" then
                name = name[1]
            end
            table.insert(result, name)
        end
    end
    return result
end

-- get target scope apis
function target_scope_apis()
    local result = {}
    for _, names in pairs(target.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get target instance apis
function target_instance_apis()
    local result = {}
    local instance = target.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "target:" .. k)
        end
    end
    return result
end

-- get option scope apis
function option_scope_apis()
    local result = {}
    for _, names in pairs(option.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get option instance apis
function option_instance_apis()
    local result = {}
    local instance = option.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "option:" .. k)
        end
    end
    return result
end

-- get rule scope apis
function rule_scope_apis()
    local result = {}
    for _, names in pairs(rule.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get rule instance apis
function rule_instance_apis()
    local result = {}
    local instance = rule.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "rule:" .. k)
        end
    end
    return result
end


-- get package scope apis
function package_scope_apis()
    local result = {}
    for _, names in pairs(package.apis()) do
        for _, name in ipairs(names) do
            if type(name) == "table" then
                name = name[1]
            end
            table.insert(result, name)
        end
    end
    return result
end

-- get package instance apis
function package_instance_apis()
    local result = {}
    local instance = package.new()
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "package:" .. k)
        end
    end
    return result
end

-- get toolchain scope apis
function toolchain_scope_apis()
    local result = {}
    for _, names in pairs(toolchain.apis()) do
        for _, name in ipairs(names) do
            table.insert(result, name)
        end
    end
    return result
end

-- get toolchain instance apis
function toolchain_instance_apis()
    local result = {}
    local instance = toolchain.load("clang")
    for k, v in pairs(instance) do
        if not k:startswith("_") and type(v) == "function" then
            table.insert(result, "toolchain:" .. k)
        end
    end
    return result
end

-- get scope apis
function scope_apis()
    local result = {}
    table.join2(result, project_scope_apis())
    table.join2(result, target_scope_apis())
    table.join2(result, option_scope_apis())
    table.join2(result, rule_scope_apis())
    table.join2(result, package_scope_apis())
    table.join2(result, toolchain_scope_apis())
    table.sort(result)
    return result
end

-- get instance apis
function instance_apis()
    local result = {}
    table.join2(result, target_instance_apis())
    table.join2(result, option_instance_apis())
    table.join2(result, rule_instance_apis())
    table.join2(result, package_instance_apis())
    table.join2(result, toolchain_instance_apis())
    table.sort(result)
    return result
end

-- get builtin module apis
function builtin_module_apis()
    local builtin_modules = table.clone(sandbox.builtin_modules())
    builtin_modules.pairs = nil
    builtin_modules.ipairs = nil
    local result = {}
    for name, value in pairs(builtin_modules) do
        if type(value) == "table" then
            for k, v in pairs(value) do
                if not k:startswith("_") and type(v) == "function" then
                    table.insert(result, name .. "." .. k)
                end
            end
        elseif type(value) == "function" then
            table.insert(result, name)
        end
    end
    table.insert(result, "ipairs")
    table.insert(result, "pairs")
    table.sort(result)
    return result
end

-- get import module apis
function import_module_apis()
    local result = {}
    local moduledirs = module.directories()
    for _, moduledir in ipairs(moduledirs) do
        moduledir = path.absolute(moduledir)
        local modulefiles = os.files(path.join(moduledir, "**.lua|private/**.lua|core/tools/**.lua|detect/tools/**.lua"))
        if modulefiles then
            for _, modulefile in ipairs(modulefiles) do
                local modulename = path.relative(modulefile, moduledir)
                if path.filename(modulename) == "main.lua" then
                    modulename = path.directory(modulename)
                end
                modulename = modulename:gsub("/", "."):gsub("%.lua", "")
                local instance = import(modulename, {try = true, anonymous = true})
                if _is_callable(instance) then
                    table.insert(result, modulename)
                elseif type(instance) == "table" then
                    for k, v in pairs(instance) do
                        if not k:startswith("_") and type(v) == "function" then
                            table.insert(result, modulename .. "." .. k)
                        end
                    end
                end
            end
        end
    end
    table.sort(result)
    return result
end

-- get all apis
function apis()
    return {scope = scope_apis(),
            instance = instance_apis(),
            builtin_module = builtin_module_apis(),
            import_module = import_module_apis()}
end

-- show all apis
function main()
    config.load()
    local result = apis()
    if result then
        showlist(result)
    end
end