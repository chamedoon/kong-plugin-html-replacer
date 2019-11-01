local helpers = require "spec.helpers"
local cjson = require "cjson"
-- local DataDumper = require "spec.DataDumper" -- for troubleshooting purpose

for _, strategy in helpers.each_strategy() do
  describe("html replacer", function()

    local bp = helpers.get_db_utils()
    local service, route1, route2, route3, route4, admin_client, proxy_client

    setup(function()
      service = bp.services:insert {
        name = "test-service",
        host = "httpbin.org",
        port = 80,
      }

      route1 = bp.routes:insert({
        hosts = { "test1.com" },
        service = { id = service.id }
      })

      bp.plugins:insert {
        name     = "html-replacer",
        route = { id = route1.id },
        config = {
          search = "httpbin.org",
          replace_with = "example.xyz",
        }
      }

      route2 = bp.routes:insert({
        hosts = { "test2.com" },
        service = { id = service.id }
      })

      bp.plugins:insert {
        name     = "html-replacer",
        route = { id = route2.id },
        config = {
          search = "httpbin.org",
        }
      }

      route3 = bp.routes:insert({
        hosts = { "test3.com" },
        service = { id = service.id }
      })

      bp.plugins:insert {
        name     = "html-replacer",
        route = { id = route3.id },
      }

      route4 = bp.routes:insert({
        hosts = { "test4.com" },
        service = { id = service.id }
      })

      bp.plugins:insert {
        name     = "html-replacer",
        route = { id = route4.id },
        config = {
          replace_with = "example.xyz",
        }
      }

      -- start Kong with your testing Kong configuration (defined in "spec.helpers")
      assert(helpers.start_kong( {
        database = strategy,
        plugins = "bundled,html-replacer" } ))

      admin_client = helpers.admin_client()
    end)

    teardown(function()
      if admin_client then
        admin_client:close()
      end

      helpers.stop_kong()

    end)

    before_each(function()
      proxy_client = helpers.proxy_client()
    end)

    after_each(function()
      if proxy_client then
        proxy_client:close()
      end
    end)

    describe("replace feature", function()
      it("should make changes", function()
        local res = assert(proxy_client:send {
          method = "GET",
          path = "/",
          headers = {
            ["Host"] = "test1.com",
          }
        })

        local body = assert.res_status(200, res)
        assert.is.falsy(string.match(body, 'httpbin.org'))
        assert.is.truthy(string.match(body, 'example.xyz'))
      end)

      it("should remove searched text when replace was not set", function()
        local res = assert(proxy_client:send {
          method = "GET",
          path = "/",
          headers = {
            ["Host"] = "test2.com",
          }
        })

        local body = assert.res_status(200, res)
        assert.is.falsy(string.match(body, 'httpbin.org'))
      end)

      it("should not make any changes to non-html content", function()
        local res = assert(proxy_client:send {
          method = "GET",
          path = "/get",
          headers = {
            ["Host"] = "test1.com",
          }
        })

        local body = assert.res_status(200, res)
        assert.is.falsy(string.match(body, 'example.xyz'))
        local json = cjson.decode(body)
        assert.is.table(json)
      end)

      it("should not make any changes without configuration", function()
        local res = assert(proxy_client:send {
          method = "GET",
          path = "/",
          headers = {
            ["Host"] = "test3.com",
          }
        })

        local body = assert.res_status(200, res)
        assert.is.falsy(string.match(body, 'example.xyz'))
        assert.is.truthy(string.match(body, 'httpbin.org'))
      end)

      it("should not make any changes without search configuration", function()
        local res = assert(proxy_client:send {
          method = "GET",
          path = "/",
          headers = {
            ["Host"] = "test4.com",
          }
        })

        local body = assert.res_status(200, res)
        assert.is.falsy(string.match(body, 'example.xyz'))
        assert.is.truthy(string.match(body, 'httpbin.org'))
      end)
    end)
  end)
end
