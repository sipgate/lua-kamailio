require 'busted.runner'()

local function init_mock(options)
  -- mock global variable 'KSR'
  local ksr_mock = {
    maxfwd = {
      process_maxfwd = function(counter)
        if options.maxfwdReached then
          return -1
        else
          return 1
        end
      end,
    },
  }
  _G["KSR"] = mock(ksr_mock)

  local core_mock = {
    exit = function() end
  }
  _G["core"] = mock(core_mock)

  local reply_mock = {
    stateless = function(cause, reason) end,
  }
  _G["reply"] = mock(reply_mock)
end

local actions = require "kamailio/actions"

describe("Check max forwards -> ", function()
  it("Do not reject if maxfwd check succedded", function()
    init_mock{maxfwdReached = false}
    actions.reject_looping_requests()
    assert.spy(core.exit).was.called(0)
    assert.spy(reply.stateless).was.called(0)
  end)

  it("Reject, if maxfwd check fails", function()
    init_mock{maxfwdReached = true}
    actions.reject_looping_requests()
    assert.spy(core.exit).was.called(1)
    assert.spy(reply.stateless).was.called_with(483, "Too Many Hops")
  end)
end)

