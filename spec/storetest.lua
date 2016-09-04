#! /usr/bin/env lua
--
-- storetest.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local assert = require "luassert"
local P = require "storefront.path"

local function test_store_methods(s, nocall)
   assert.is_function(s.begin_transaction)
   assert.is_function(s.end_transaction)
   assert.is_function(s.transact)
   assert.is_function(s.get)
   assert.is_function(s.set)
   assert.is_function(s.del)
   assert.is_function(s.has)
   if not nocall then
      s:get(P"foo")
      s:set(P"foo", "42")
      s:del(P"foo", "42")
      s:has(P"foo")
      s:query("*")
   end
end

local function test_store_set_get(s, p)
   assert.not_truthy(s:has(p))
   s:set(p, "random value")
   assert.truthy(s:has(p))
   assert.equal("random value", s:get(p))
   for path in s:query(tostring(p)) do
      assert.equal(p, path)
      break
   end
end

local function test_store_del (s, p)
   assert.is_false(s:has(p))
   s:set(p, "the answer is 42")
   assert.is_true(s:has(p))
   assert.equal("the answer is 42", s:get(p))
   s:del(p)
   assert.is_false(s:has(p))
   assert.is_nil(s:get(p))
   for path in s:query(tostring(p)) do
      error("unreachable")
   end
end

return {
   test_store_methods = test_store_methods,
   test_set_get = test_store_set_get,
   test_del = test_store_del,
}
