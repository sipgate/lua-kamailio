require 'busted.runner'()

local function init_mock(options)
  -- mock global variable 'KSR'
  local ksr_mock = {
    pv = {
      get = function(key)
        if key == "$rU" then
          if options.rU ~= nil then return options.rU else return "01234567" end
        end
      end,
      sets = function(k, v) end,
    },
    hdr = {
      append = function(header) end,
    }
  }
  _G["KSR"] = mock(ksr_mock)
  
  local message_mock = {
    is_invite = function() return options.is_invite end
  }
  _G["message"] = mock(message_mock)
end

local headers = require "kamailio/headers"

describe("Check and enable CLIR ->", function()
  it("Caller dials *31021112345", function()
    -- Initialize the mock
    init_mock{ rU = "*31021112345", is_invite = true }
    -- Call the function
    headers.suppress_cid_if_needed()
    -- Now check if everything is as expected
    assert.spy(KSR.pv.sets).was.called_with("$rU", "021112345")
    assert.spy(KSR.hdr.append).was.called_with("Privacy: id\r\n")
  end)
  it("Caller dials *31*021112345", function()
    -- Initialize the mock
    init_mock{ rU = "*31*021112345", is_invite = true }
    -- Call the function
    headers.suppress_cid_if_needed()
    -- Now check if everything is as expected
    assert.spy(KSR.pv.sets).was.called_with("$rU", "021112345")
    assert.spy(KSR.hdr.append).was.called_with("Privacy: id\r\n")
  end)
  it("Caller dials *31#021112345", function()
    -- Initialize the mock
    init_mock{ rU = "*31#021112345", is_invite = true }
    -- Call the function
    headers.suppress_cid_if_needed()
    -- Now check if everything is as expected
    assert.spy(KSR.pv.sets).was.called_with("$rU", "021112345")
    assert.spy(KSR.hdr.append).was.called_with("Privacy: id\r\n")
  end)
  it("Caller dials *31%23021112345", function()
    -- Initialize the mock
    init_mock{ rU = "*31%23021112345", is_invite = true }
    -- Call the function
    headers.suppress_cid_if_needed()
    -- Now check if everything is as expected
    assert.spy(KSR.pv.sets).was.called_with("$rU", "021112345")
    assert.spy(KSR.hdr.append).was.called_with("Privacy: id\r\n")
  end)
  it("Caller dials +4921112345", function()
    -- Initialize the mock
    init_mock{ rU = "+4921112345", is_invite = true }
    -- Call the function
    headers.suppress_cid_if_needed()
    -- Now check if everything is as expected
    assert.spy(KSR.pv.sets).was.called(0)
    assert.spy(KSR.hdr.append).was.called(0)
  end)
  it("Caller dials *31+4921112345, non-INVITE", function()
    -- Initialize the mock
    init_mock{ rU = "*31+4921112345" }
    -- Call the function
    headers.suppress_cid_if_needed()
    -- Now check if everything is as expected
    assert.spy(KSR.pv.sets).was.called_with("$rU", "+4921112345")
    assert.spy(KSR.hdr.append).was.called(0)
  end)
end)