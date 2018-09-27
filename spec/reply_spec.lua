require 'busted.runner'()

local function init_mock(options)
  -- mock global variable 'KSR'
  local ksr_mock = {
    err = function(msg) end,
    sl = {
      sl_send_reply = function(cause,reason) end,
    },
    tm = {
      t_reply = function(cause,reason) end,
    },
  }
  _G["KSR"] = mock(ksr_mock)
end

local reply = require "kamailio/reply"

describe("Check stateless reply -> ", function()
  it("Reply sent when called with valid cause", function()
    init_mock{}
    local cause = 200
    local reason = "OK"
    reply.stateless(cause, reason)
    assert.spy(KSR.sl.sl_send_reply).was.called_with(cause, reason)
  end)
  it("Reply sent with reason 'Unknown' when called only with cause", function()
    init_mock{}
    local cause = 200
    reply.stateless(cause)
    assert.spy(KSR.sl.sl_send_reply).was.called_with(cause, "Unknown")
  end)
  it("Reply not sent when called without cause", function()
    init_mock{}
    reply.stateless()
    assert.spy(KSR.sl.sl_send_reply).was.called(0)
  end)
end)

describe("Check stateful reply -> ", function()
  it("Reply sent when called with valid cause", function()
    init_mock{}
    local cause = 200
    local reason = "OK"
    reply.stateful(cause, reason)
    assert.spy(KSR.tm.t_reply).was.called_with(cause, reason)
  end)
  it("Reply sent with reason 'Unknown' when called only with cause", function()
    init_mock{}
    local cause = 200
    reply.stateful(cause)
    assert.spy(KSR.tm.t_reply).was.called_with(cause, "Unknown")
  end)
  it("Reply not sent when called without cause", function()
    init_mock{}
    reply.stateful()
    assert.spy(KSR.tm.t_reply).was.called(0)
  end)
end)