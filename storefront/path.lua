--
-- path.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local type, error, setmetatable = type, error, setmetatable
local ipairs = ipairs
local s_match, s_gmatch, s_format = string.match, string.gmatch, string.format
local t_insert, t_concat = table.insert, table.concat

local _ENV = nil


local path_component_pattern = "^[_%w%-][_%w%-%.]*$"
local path_component_split_pattern = "[^/]+"

local function construct_path(path, copy)
   if type(path) == "string" then
      local r = {}
      for component in s_gmatch(path, path_component_split_pattern) do
         t_insert(r, component)
      end
      path, copy = r, false
   elseif copy then
      local r = {}
      for i, item in ipairs(path) do r[i] = item end
      path = r
   end
   local num_components = 0
   for _, component in ipairs(path) do
      if not s_match(component, path_component_pattern) then
         error(s_format("invalid path component: %q", component))
      end
      num_components = num_components + 1
   end
   if num_components == 0 then
      error(s_format("path is empty"))
   end
   return path, num_components
end


local path = {}
path.__index = path

setmetatable(path, { __call = function (self, path, adopt)
   return setmetatable(construct_path(path, not adopt), self)
end })

function path:__tostring()
   return t_concat(self, "/")
end

function path:__eq(other)
   other = construct_path(other)
   for i, value in ipairs(self) do
      if value ~= other[i] then
         return false
      end
   end
   return true
end

function path:child(component)
   local new_path, n = construct_path(self, true)
   new_path[n + 1] = component
   return setmetatable(new_path, path)
end

function path:parent()
   local new_path, n = construct_path(self, true)
   new_path[n] = nil
   return setmetatable(new_path, path)
end

function path:sibling(component)
   local new_path, n = construct_path(self, true)
   new_path[n] = component
   return setmetatable(new_path, path)
end


return path
