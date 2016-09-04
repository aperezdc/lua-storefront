#! /usr/bin/env lua
--
-- spec_base.lua
-- Copyright (C) 2016 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local base = require "storefront.base"
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
