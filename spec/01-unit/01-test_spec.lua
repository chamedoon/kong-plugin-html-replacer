local plugin_handler = require "kong.plugins.html-replacer.handler"

describe("Plugin: html-replacer", function()
  describe("modify_response_in_body()", function()
    local body = "<html><body><h1>I love apple</h1></body></html>"

    describe("replace body text", function()
      local conf = {
        search = "apple",
        replace_with = "banana"
      }

      it("replacement works in html response", function ()
        local modified = plugin_handler.modify_response_in_body(conf, body)
        assert.are.same("<html><body><h1>I love banana</h1></body></html>", modified)
      end)

      it("does nothing when body is empty", function ()
        local modified = plugin_handler.modify_response_in_body(conf, "")
        assert.are.same("", modified)
      end)
    end)

    describe("empty conf object", function()
      local conf = {
        search = "",
        replace_with = ""
      }

      it("shold not change anything", function ()
        local result = plugin_handler.modify_response_in_body(conf, body)
        assert.are.same(body, result)
      end)
    end)

  end)
end)