--
-- path.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

--
-- A "path" is a string separated by slashes. Each slash-separated component
-- can only contain numbers, letters, dashes, underscores, and periods; and
-- the first character of a component cannot be a period. Paths are always
-- absolute.
--
-- Path objects are interned. This means that:
--
--   * The same path is represented always by the same table/object.
--   * Instantiating multiple path objects for a path continues using
--     the same unique path object.
--   * Modifying a path objects can only be done using the modification
--     functions. The path components are read-only (__newindex is used
--     to ensure this).
--

local setmetatable, getmetatable = setmetatable, getmetatable
local type, error, ipairs, tostring = type, error, ipairs, tostring
local s_match, s_gmatch, s_format = string.match, string.gmatch, string.format
local t_insert, t_concat = table.insert, table.concat

local _ENV = nil


local path_component_pattern = "^[_%w%-][_%w%-%.]*$"
local path_component_split_pattern = "[^/]+"


-- Weak table of "live" path objects.
local live_paths = setmetatable({}, { __mode = "v" })


-- Path object prototype.
local path = {}
path.__index = path

function path:__newindex(key, value)
   error("path objects are immutable")
end

--
-- Creates a copy of a path without checking its components. This is used
-- from the methods which return a new modified path based on another path,
-- in order to avoid overhead.
--
local function unsafe_copy(path)
   local result, num_components = {}, 0
   for i, component in ipairs(path) do
      result[i] = component
      num_components = num_components + 1
   end
   return result, num_components
end

local function check_path_component(s)
   if s_match(s, path_component_pattern) then return s end
   error(s_format("invalid path component: %q", s))
end

local function canonicalize(path, copy)
   local result, num_components

   if type(path) == "string" then
      -- Split paths given as strings, in order to canonicalize them.
      result, num_components = {}, 0
      for component in s_gmatch(path, path_component_split_pattern) do
         t_insert(result, check_path_component(component))
         num_components = num_components + 1
      end
   elseif copy then
      -- Copy and check components in a single go.
      result, num_components = {}, 0
      for i, component in ipairs(path) do
         result[i] = check_path_component(component)
         num_components = num_components + 1
      end
   else
      -- Check path components and count them.
      result, num_components = path, 0
      for _, component in ipairs(result) do
         if not s_match(component, path_component_pattern) then
            error(s_format("invalid path component: %q", component))
         end
         num_components = num_components + 1
      end
   end

   if num_components == 0 then
      error(s_format("path is empty"))
   end

   return result, num_components
end


--
-- Accepts a table with a list of path components, and if the path is in the
-- table of "live" path objects, return the existing object. Otherwise, create
-- a new path object, convert the passed table into a path object, add it to
-- the weak tale of "live" objects and return it.
--
local function intern(path_components)
   local path_string = t_concat(path_components, "/")
   local path_object = live_paths[path_string]
   if not path_object then
      -- Convert into a path object: all modifications *must* be done before
      -- setting the metatable, because its __newindex produces an error.
      path_components.string = path_string
      path_object = setmetatable(path_components, path)
      live_paths[path_string] = path_object
   end
   return path_object
end


setmetatable(path, { __call = function (self, path, adopt)
   return intern(canonicalize(path, not adopt))
end })

function path:__tostring()
   return self.string
end

function path:child(component)
   check_path_component(component)
   local new_path, n = unsafe_copy(self)
   new_path[n + 1] = component
   return intern(new_path)
end

function path:parent()
   local new_path, n = unsafe_copy(self)
   new_path[n] = nil
   return intern(new_path)
end

function path:sibling(component)
   check_path_component(component)
   local new_path, n = unsafe_copy(self)
   new_path[n] = component
   return intern(new_path)
end

function path:__concat(other)
   local new_path, n = unsafe_copy(self)
   local other_type = type(other)
   if other_type == "table" then
      if getmetatable(other) == path then
         -- No need to check components.
         for i, component in ipairs(other) do
            new_path[n + i] = component
         end
      else
         -- Check path components.
         for i, component in ipairs(other) do
            new_path[n + i] = check_path_component(component)
         end
      end
   elseif other_type == "string" then
      -- Canonicalize the string into a new path.
      for i, component in ipairs(canonicalize(other)) do
         new_path[n + i] = component
      end
   else
      -- Append the stringization of the value.
      new_path[n + 1] = check_path_component(tostring(other))
   end
   return intern(new_path)
end


function path.check(p, convert)
   if getmetatable(p) == path then
      return p
   elseif convert then
      return path(p)
   else
      error("argument is not a path object")
   end
end


return path
