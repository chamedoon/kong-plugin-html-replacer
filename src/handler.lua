local BasePlugin = require "kong.plugins.base_plugin"

local HtmlReplacerHandler = BasePlugin:extend()

HtmlReplacerHandler.PRIORITY = 2000


-- Check if search is present in the plugin configuration
-- Return True or False
local function is_search_set(conf)
    if conf['search'] ~= nil then
        return #conf['search'] > 0
    end
    return false
end


-- Check if content_type is HTML
-- Return True of False
local function is_html(content_type)
    return string.match(string.lower(content_type), '^text/html')
end


-- Replace response in html
function HtmlReplacerHandler.modify_response_in_body(conf, html)
    if (html == nil) then
        print("no content")
        return nil
    end

    local search = conf.search or ""
    local replace = conf.replace_with or ""

    return string.gsub(html, search, replace)
end


function HtmlReplacerHandler:new()
    HtmlReplacerHandler.super.new(self, "html-replacer")
end

function HtmlReplacerHandler:header_filter(conf)
    HtmlReplacerHandler.super.header_filter(self)

    if is_search_set(conf) and is_html(ngx.header["Content-Type"]) then
        ngx.header["content-length"] = nil
        -- adds a header for troubleshooting purposes
        -- ngx.header["CONTENT_MODIFIED_BY"] = "kong-plugin-html-replacer"
    end
end

function HtmlReplacerHandler:body_filter(conf)
    HtmlReplacerHandler.super.body_filter(self)

    if is_search_set(conf) and is_html(kong.response.get_header("Content-Type")) then

        local data, eof = ngx.arg[1], ngx.arg[2]
        local ctx = ngx.ctx

        ctx.rt_body_chunks = ctx.rt_body_chunks or ""

        if eof then
            local body_text = HtmlReplacerHandler.modify_response_in_body(conf, ctx.rt_body_chunks)
            ngx.arg[1] = body_text
        else
            ctx.rt_body_chunks = ctx.rt_body_chunks .. data
            ngx.arg[1] = nil
        end
    end
end

return HtmlReplacerHandler
