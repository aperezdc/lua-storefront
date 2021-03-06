--
-- base.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local error, xpcall, setmetatable, pairs = error, xpcall, setmetatable, pairs
local assert, type, select, d_traceback = assert, type, select, debug.traceback
local tostring, s_gsub, s_match = tostring, string.gsub, string.match
local unpack = table.unpack or unpack

local islice = require "itertools" .islice
local sorted = require "itertools" .sorted
local filter = require "itertools" .filter

local _ENV = nil

--
-- In Lua 5.1 xpcall() does not pass additional argument down to the callback
-- function, so we replace the function by a version which uses a closure to
-- pass them.
--
if not select(2, xpcall(function (x) return x ~= nil end, function() end, 1)) then
   local do_xpcall = xpcall
   xpcall = function (callback, error_handler, ...)
      local args, narg = { ... }, select("#", ...)
      return do_xpcall(function ()
         return callback(unpack(args, 1, narg))
      end, error_handler)
   end
end

local function error_add_traceback (message)
   local tp = type(message)
   if tp ~= "string" and tp ~= "number" then
      return message
   end
   return d_traceback(message, 2)
end


local class_meta = {}

function class_meta:__call(...)
   local obj = {}
   setmetatable(obj, self)
   obj:__init(...)
   return obj
end

function class_meta:__tostring()
   return "<class " .. self.__name .. ">"
end

function class_meta:__add(name)
   local cls = {}
   for k, v in pairs(self) do
      cls[k] = v
   end
   cls.__index = cls
   cls.__name = name
   return setmetatable(cls, class_meta)
end


local base = {}

-- Construct the base class manually.
base.class = class_meta.__add({
   __tostring = function (self)
      return "<" .. self.__name .. ">"
   end,
   __init = function (self, properties)
      if properties then
         for k, v in pairs(properties) do
            self[k] = v
         end
      end
   end,
}, "storefront.base.class")


base.store = base.class + "storefront.base.store"

function base.store:begin_transaction()
   return true  -- Dummy implementation.
end

function base.store:end_transaction(token)
   return true  -- Dummy implementation.
end

function base.store:transact(callable, ...)
   local token = assert(self:begin_transaction())
   assert(xpcall(callable, error_add_traceback, self, token, ...))
   assert(self:end_transaction(token))
end

function base.store:get(path)
   error("store:get() unimplemented")
end

function base.store:set(path, value)
   error("store:set() unimplemented")
end

function base.store:del(path)
   error("store:del() unimplemented")
end

function base.store:has(path)
   return self:get(path) ~= nil
end

function base.store:query(pattern, limit, offset)
   error("store:query() unimplemented")
end


base.shim = base.store + "storefront.base.shim"

function base.shim:__init(store)
   base.store.__init(self)
   self.child = store
end

function base.shim:__tostring()
   return "<" .. self.__name .. " " .. tostring(self.child) .. ">"
end

function base.shim:get(...) return self.child:get(...) end
function base.shim:set(...) return self.child:set(...) end
function base.shim:del(...) return self.child:del(...) end
function base.shim:has(...) return self.child:has(...) end
function base.shim:query(...) return self.child:query(...) end


base.cache = base.shim + "storefront.base.cache"

function base.cache:__init(store, cache)
   base.shim.__init(self, store)
   self.cache = cache
end

function base.cache:__tostring()
   return "<" .. self.__name .. " " .. tostring(self.child)
       .. " cache=" .. tostring(self.cache) .. ">"
end

function base.cache:get(path)
   local value = self.cache:get(path)
   if value == nil then
      value = self.child:get(path)
      if value ~= nil then
         self.cache:set(path, value)
      end
   end
   return value
end

function base.cache:set(path, value)
   self.cache:set(path, value)
   self.child:set(path, value)
end

function base.cache:del(path)
   self.cache:del(path)
   self.child:del(path)
end

function base.cache:has(path)
   return self.cache:has(path) or self.child:has(path)
end


local function make_pattern_matcher (pattern)
   pattern = (s_gsub(pattern, "[%-%.%+%[%]%(%)%$%^%%%?%*]", "%%%1"))
   pattern = (s_gsub(pattern, "%%%*%%%*", ".*"))
   pattern = (s_gsub(pattern, "%%%*", "[^/]*"))
   pattern = (s_gsub(pattern, "%%%?", "."))
   pattern = "^" .. pattern .. "$"
   return function (s)
      return s_match(tostring(s), pattern) ~= nil
   end
end

function base.query_iterable(iterable, pattern, limit, offset)
   -- TODO: Canonicalize pattern first.

   -- Only apply the filtering when not iterating over all keys.
   if pattern ~= "**" then
      local matches_pattern = make_pattern_matcher(pattern)
      iterable = filter(matches_pattern, iterable)
   end

   if offset == nil then
      offset = 1
   end

   if limit == nil then
      if offset > 1 then
         iterable = islice(sorted(iterable), offset)
      end
   else
      iterable = islice(sorted(iterable), offset, offset + limit - 1)
   end

   return iterable
end


return base
