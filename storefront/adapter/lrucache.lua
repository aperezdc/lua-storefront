--
-- lrucache.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local tostring = tostring

local keys = require "storefront.itertools" .keys
local map = require "storefront.itertools" .map
local base = require "storefront.base"
local P = require "storefront.path"
local check_path, query_iterable = P.check, base.query_iterable

local _ENV = nil


local store = base.store + "storefront.adapter.lrucache.store"

function store:__init(size)
   base.store.__init(self)
   self._table = {}
   self._head = {}
   self._head._next = self._head
   self._head._prev = self._head
   self._list_size = 1
   self:size(size)
end

function store:__tostring()
   return "<" .. self.__name .. " size=" .. tostring(self.size) .. ">"
end

local function _add_tail_nodes(self, n)
   for _ = 1, n do
      local node = { _next = self._head, _prev = self._head._prev }
      self._head._prev._next = node
      self._head._prev = node
   end
   self._list_size = self._list_size + n
end

local function _del_tail_nodes(self, n)
   for _ = 1, n do
      local node = self._head._prev
      if node.key ~= nil then
         self._table[node.key] = nil
      end
      self._head._prev = node._prev
      node._prev._next = self._head
      node._prev = nil
      node._next = nil
      node.value = nil
      node.key = nil
   end
   self._list_size = self._list_size - n
end

local function _size(self, size)
   if size ~= nil and size > 0 then
      if size > self._list_size then
         _add_tail_nodes(self, size - self._list_size)
      elseif size < self._list_size then
         _del_tail_nodes(self, self._list_size - size)
      end
   end
   return self._list_size
end

store.__len = _size
store.size = _size

local function _move_to_front(self, node)
   node._prev._next = node._next
   node._next._prev = node._prev
   node._prev = self._head._prev
   node._next = self._head._prev._next
   node._next._prev = node
   node._prev._next = node
end

function store:get(path)
   local key = tostring(path)
   local node = self._table[key]
   if node then
      _move_to_front(self, node)
      self._head = node
      return node.value
   end
   return nil
end

function store:set(path, value)
   local key = tostring(path)
   local node = self._table[key]
   if node then
      -- Keep node, replace value.
      node.value = value
      _move_to_front(self, node)
      self._head = node
   else
      -- Choose a node for the new item. Evict the last item in the list when
      -- the cache is full, or pick an empty node. There are empty nodes are
      -- always at the end.
      local node = self._head._prev
      if node.key then
         self._table[node.key] = nil  -- Evict.
      end
      node.key, node.value = key, value
      self._table[key] = node
      -- The list is circular; it's enough to move the head pointer.
      self._head = node
   end
end

function store:del(path)
   local key = tostring(path)
   local node = self._table[key]
   if node then
      self._table[key] = nil
      node.key, node.value = nil, nil
      -- Place the empty node at the end of the circular list, which is the
      -- same as moving it to the front and changing the head pointer.
      _move_to_front(self, node)
      self._head = node._next
   end
end

function store:has(path)
   return self._table[tostring(path)] ~= nil
end

function store:query(pattern, limit, offset)
   return query_iterable(map(P, keys(self._table)), pattern, limit, offset)
end


local lrucache = base.cache + "storefront.adapter.lrucache"

function lrucache:__init(child, size)
   base.cache.__init(self, child, store(size))
end

return lrucache
