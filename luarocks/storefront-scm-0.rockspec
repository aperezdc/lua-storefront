package = "storefront"
version = "scm-0"
source = {
   url = "git://github.com/aperezdc/lua-storefront"
}
description = {
   maintainer = "Adrián Pérez de Castro <aperez@igalia.com>",
   summary = "Unified key-value store API with multiple backends",
   homepage = "https://github.com/aperezdc/lua-storefront",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1",
   "itertools >= 0.1",
}
build = {
   type = "builtin",
   modules = {
      ["storefront.base"] = "storefront/base.lua",
      ["storefront.path"] = "storefront/path.lua",

      ["storefront.adapter.lrucache"] = "storefront/adapter/lrucache.lua",

      ["storefront.backend.inmem"] = "storefront/backend/inmem.lua",
   }
}
