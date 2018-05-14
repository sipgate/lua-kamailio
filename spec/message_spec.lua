require 'busted.runner'()

local function init_mock(options)
  -- mock global variable 'KSR'
  local ksr_mock = {
    pv = {
      get = function(key)
        if key == "$rU" then
          if options.rU ~= nil then return options.rU else return "01234567" end
        elseif key == "$ua" then return options.ua end
      end,
      sets = function(k, v) end,
      is_null = function(key)
        if key == "$ua" then
          if options.ua then return false else return true end
        end
      end,
    },
    hdr = {
      append = function(header) end,
    }
  }
  _G["KSR"] = mock(ksr_mock)  
end


local message = require "kamailio/message"

describe("Check for bad user agent ->", function()
  it("UA is friendly-scanner", function()
    init_mock{ ua = "friendly-scanner" }
    ua_check = message.is_from_bad_user_agent()
    assert.are.equal(1, ua_check)
  end)
  it("UA is sipcli-1.1.8", function()
    init_mock{ ua = "sipcli-1.1.8" }
    ua_check = message.is_from_bad_user_agent()
    assert.are.equal(1, ua_check)
  end)
  it("UA is Asterisk 15.1.1", function()
    init_mock{ ua = "Asterisk 15.1.1" }
    ua_check = message.is_from_bad_user_agent()
    assert.are.equal(nil, ua_check)
  end)
end)
