--
-- inmem.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local keys = require "storefront.itertools" .keys
local map = require "storefront.itertools" .map
local base = require "storefront.base"
local P = require "storefront.path"
local check_path, query_iterable = P.check, base.query_iterable

local _ENV = nil


local inmem = base.store + "storefront.backend.inmem"

function inmem:__init()
   base.store:__init()
   self._data = {}
end

function inmem:get(path)
   return self._data[check_path(path).string]
end

function inmem:set(path, value)
   self._data[check_path(path).string] = value
end

function inmem:del(path)
   self._data[check_path(path).string] = nil
end

function inmem:has(path)
   return self._data[check_path(path).string] ~= nil
end

function inmem:query(pattern, limit, offset)
   return query_iterable(map(P, keys(self._data)), pattern, limit, offset)
end

return inmem
