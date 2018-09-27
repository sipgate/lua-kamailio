require 'busted.runner'()

local function init_mock(options)
  -- mock global variable 'KSR'
  local ksr_mock = {
    err = function(msg) end,
    maxfwd = {
      process_maxfwd = function(counter)
        if options.maxfwdReached then
          return -1
        else
          return 1
        end
      end,
    },
    pv = {
      get = function(key)
        if key == "$si" then return options.si or "1.2.3.4"
        elseif key == "$sp" then return options.sp or "55555" end
      end,
    },
    registrar = {
      save = function(table, flags) if options.location_saved then return 1 else return -1 end end,
    },
    sanity = {
      sanity_check = function(flags, uri_checks) if options.is_sane then return 1 else return -1 end end,
    },
  }
  _G["KSR"] = mock(ksr_mock)

  local core_mock = {
    exit = function() end
  }
  _G["core"] = mock(core_mock)

  local message_mock = {
    is_options = function() return options.is_options end,
    is_request_to_local_request_domain = function() return options.is_request_to_local_request_domain end,
    has_empty_request_user = function() return options.has_empty_request_user end,
  }
  _G["message"] = mock(message_mock)

  local reply_mock = {
    stateless = function(cause, reason) end,
    with_stateless_error_and_exit = function() end,
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

describe("Save Registration -> ", function()
  it("Saving Registration was successful", function()
    init_mock{ location_saved = true }
    actions.save_register()
    assert.spy(reply.with_stateless_error_and_exit).was.called(0)
  end)
  it("Saving Registration was unsuccessful", function()
    init_mock{ location_saved = false }
    actions.save_register()
    assert.spy(reply.with_stateless_error_and_exit).was.called()
  end)
end)

describe("Handle OPTIONS -> ", function()
  it("Message is an OPTIONS request, request user is empty, directed to local domain", function()
    init_mock{ is_options = true, has_empty_request_user = true, is_request_to_local_request_domain = true }
    actions.handle_options()
    assert.spy(reply.stateless).was.called_with(200, "Keepalive")
    assert.spy(core.exit).was.called()
  end)
  it("Message is an OPTIONS request but request user is not empty", function()
    init_mock{ is_options = true, has_empty_request_user = false, is_request_to_local_request_domain = true }
    actions.handle_options()
    assert.spy(reply.stateless).was.called(0)
  end)
  it("Message is an OPTIONS request but not directed to the local domain", function()
    init_mock{ is_options = true, has_empty_request_user = true, is_request_to_local_request_domain = false }
    actions.handle_options()
    assert.spy(reply.stateless).was.called(0)
  end)
  it("Message is NOT an OPTIONS request", function()
    init_mock{ is_options = false, has_empty_request_user = true, is_request_to_local_request_domain = true }
    actions.handle_options()
    assert.spy(reply.stateless).was.called(0)
  end)
end)

describe("Sanity Check -> ", function()
  it("Sanity Check passed", function()
    init_mock{ is_sane = true }
    actions.check_sanity()
    assert.spy(KSR.sanity.sanity_check).was.called()
    assert.spy(KSR.err).was.called(0)
    assert.spy(core.exit).was.called(0)
  end)
  it("Sanity Check passed", function()
    init_mock{ is_sane = false }
    actions.check_sanity()
    assert.spy(KSR.sanity.sanity_check).was.called()
    assert.spy(KSR.err).was.called()
    assert.spy(core.exit).was.called()
  end)
end)
