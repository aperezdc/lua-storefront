#! /usr/bin/env lua
--
-- spec_base.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local base = require "storefront.base"
local iter = require "storefront.itertools"
local storetest = require "spec.storetest"

describe("storefront.base.class", function ()
   describe("__tostring", function ()
      it("works in classes", function ()
         assert.equal("<class storefront.base.class>", tostring(base.class))
      end)
      it("works in instances", function ()
         local obj = base.class()
         assert.equal("<storefront.base.class>", tostring(obj))
      end)
      it("works in derived classes", function ()
         local derived = base.class + "derived"
         assert.equal("<class derived>", tostring(derived))
      end)
      it("works in derived class instances", function ()
         local derived = base.class + "derived"
         local obj = derived()
         assert.equal("<derived>", tostring(obj))
      end)
   end)

   describe("__init", function ()
      it("sets properties by default", function ()
         local obj = base.class { name = "Peter", surname = "Parker" }
         assert.equal("Peter", obj.name)
         assert.equal("Parker", obj.surname)
      end)
      it("can be overriden", function ()
         local derived = base.class + "derived"
         stub(derived, "__init")
         local obj = derived("__init argument")
         assert.stub(derived.__init).called_with(obj, "__init argument")
      end)
   end)
end)

describe("storefront.base.store", function ()
   it("has basic store methods", function ()
      storetest(base.store, true)
   end)

   it("can be subclassed", function ()
      local derived_class = base.store + "derived"
      assert.is_table(derived_class)
      assert.not_same(derived_class, base.store)
      local instance = derived_class()
      assert.is_table(instance)
      storetest(instance, true)
      assert.not_equal(derived_class, instance)
   end)

   describe(":get", function ()
      it("raises an error", function ()
         local store = base.store()
         assert.has_error(function ()
            store:get("foo.bar")
         end)
      end)
   end)

   describe(":set", function ()
      it("raises an error", function ()
         local store = base.store()
         assert.has_error(function ()
            store:set("foo.bar", "baz")
         end)
      end)
   end)

   describe(":del", function ()
      it("raises an error", function ()
         local store = base.store()
         assert.has_error(function ()
            store:del("foo.bar")
         end)
      end)
   end)

   describe(":has", function ()
      it("raises an error", function ()
         local store = base.store()
         assert.has_error(function ()
            store:has("foo.bar")
         end)
      end)
   end)

   describe(":query", function ()
      it("raises an error", function ()
         local store = base.store()
         assert.has_error(function ()
            store:query("foo.*")
         end)
      end)
   end)

   describe(":transact", function ()
      it("invokes the callback", function ()
         local store = base.store()
         local s = spy.new(function () end)
         store:transact(s)
         assert.spy(s).called_with(store, match._)
      end)
      it("passes arguments to the callback", function ()
         local store = base.store()
         local s = spy.new(function () end)
         store:transact(s, "Peter", "Parker")
         assert.spy(s).called_with(store, match._, "Peter", "Parker")
      end)
      it("wraps errors", function ()
         local store = base.store()
         assert.has_error(function ()
            store:transact(function () error("duh!") end)
         end)
      end)
      it("passes the transaction token", function ()
         local derived = base.store + "derived"
         function derived:begin_transaction()
            return "transaction token"
         end
         local store = derived()
         local s = spy.new(function () end)
         store:transact(s)
         assert.spy(s).called_with(store, "transaction token")
      end)
      it("passes the transaction token to :end_transaction", function ()
         local derived = base.store + "derived"
         function derived:begin_transaction()
            return "transaction token"
         end
         local store = derived()
         local s = spy.on(store, "end_transaction")
         store:transact(function () end)
         assert.spy(s).called_with(store, "transaction token")
      end)
   end)
end)

describe("storefront.base.query_iterable", function ()

   local items = {
      "foo",
      "bar",
      "foo/foo",
      "foo/bar",
      "bar/foo",
      "bar/bar",
      "foo/bar/baz",
      "foo/baz/bar",
   }

   it("returns all items with '**'", function ()
      local result = {}
      local count = 0
      for r in base.query_iterable(iter.each(items), "**") do
         result[r] = true
         count = count + 1
      end
      for _, item in ipairs(items) do
         assert.truthy(result[item])
      end
      assert.equal(#items, count)
   end)

   it("does long-match prefix filtering", function ()
      local resultset = {
         ["foo/foo"] = true,
         ["foo/bar"] = true,
         ["foo/bar/baz"] = true,
         ["foo/baz/bar"] = true,
      }
      local count = 0
      for item in base.query_iterable(iter.each(items), "foo/**") do
         assert.truthy(resultset[item])
         count = count + 1
      end
      assert.equal(4, count)
   end)

   it("does short-match prefix filtering", function ()
      local resultset = { ["foo/foo"] = true, ["foo/bar"] = true }
      local count = 0
      for item in base.query_iterable(iter.each(items), "foo/*") do
         assert.truthy(resultset[item])
         count = count + 1
      end
      assert.equal(2, count)
   end)

   it("does long-match suffix filtering", function ()
      local resultset = {
         ["foo/bar"] = true,
         ["bar/bar"] = true,
         ["foo/baz/bar"] = true,
      }
      local count = 0
      for item in base.query_iterable(iter.each(items), "**/bar") do
         assert.truthy(resultset[item])
         count = count + 1
      end
      assert.equal(3, count)
   end)

   it("does short-match suffix filtering", function ()
      local resultset = { ["foo/bar"] = true, ["bar/bar"] = true }
      local count = 0
      for item in base.query_iterable(iter.each(items), "*/bar") do
         assert.truthy(resultset[item])
         count = count + 1
      end
      assert.equal(2, count)
   end)

   it("can paginate results", function ()
      local s = iter.collect(iter.sorted(iter.each(items)))
      local r = iter.collect(base.query_iterable(iter.each(items), "**", 2))
      assert.equal(2, #r)
      assert.equal(s[1], r[1])
      assert.equal(s[2], r[2])
      r = iter.collect(base.query_iterable(iter.each(items), "**", 2, 3))
      assert.equal(2, #r)
      assert.equal(s[3], r[1])
      assert.equal(s[4], r[2])
      -- Now get the rest of items
      r = iter.collect(base.query_iterable(iter.each(items), "**", nil, 5))
      assert.equal(#items - 4, #r)
   end)
end)
