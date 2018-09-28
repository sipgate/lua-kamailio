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
    tm = {
      t_is_set = function(targetRoute)
        if targetRoute == "branch_route" then
          if options.isBranchRouteSet then
            return 1
          else
            return -1
          end
        elseif targetRoute == "onreply_route" then
          if options.isOnReplyRouteSet then
            return 1
          else
            return -1
          end
        elseif targetRoute == "failure_route" then
          if options.isFailureRouteSet then
            return 1
          else
            return -1
          end
        end
      end,

      t_on_branch = function() end,
      t_on_reply = function() end,
      t_on_failure = function() end,

      t_relay = function()
        if options.relaySuccessful then
          return 1
        else
          return -1
        end
      end
    },
  }
  _G["KSR"] = mock(ksr_mock)

  local core_mock = {
    exit = function() end
  }
  _G["core"] = mock(core_mock)

  local message_mock = {
    is_options = function() return options.is_options end,
    is_invite = function() return options.is_invite end,
    is_bye = function() return options.is_bye end,
    is_subscribe = function() return options.is_subscribe end,
    is_update = function() return options.is_update end,
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
    assert.spy(core.exit).was.called()
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

describe("relay message checks -> ", function()
  it("Is branch_route already set for INVITE", function()
    init_mock{ isBranchRouteSet = true, is_invite = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route set for INVITE", function()
    init_mock{ isBranchRouteSet = false, is_invite = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called()
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route already set for BYE", function()
    init_mock{ isBranchRouteSet = true, is_bye = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route set for BYE", function()
    init_mock{ isBranchRouteSet = false, is_bye = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called()
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route already set for SUBSCRIBE", function()
    init_mock{ isBranchRouteSet = true, is_subscribe = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route set for SUBSCRIBE", function()
    init_mock{ isBranchRouteSet = false, is_subscribe = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called()
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route already set for UPDATE", function()
    init_mock{ isBranchRouteSet = true, is_update = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is branch_route set for UPDATE", function()
    init_mock{ isBranchRouteSet = false, is_update = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_branch).was.called()
    assert.spy(core.exit).was.called()
  end)

  it("Is onreply_route already set for INVITE", function()
    init_mock{ isOnReplyRouteSet = true, is_invite = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_reply).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is onreply_route set for INVITE", function()
    init_mock{ isOnReplyRouteSet = false, is_invite = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_reply).was.called()
    assert.spy(core.exit).was.called()
  end)
  it("Is onreply_route already set for SUBSCRIBE", function()
    init_mock{ isOnReplyRouteSet = true, is_subscribe = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_reply).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is onreply_route set for SUBSCRIBE", function()
    init_mock{ isOnReplyRouteSet = false, is_subscribe = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_reply).was.called()
    assert.spy(core.exit).was.called()
  end)
  it("Is onreply_route already set for UPDATE", function()
    init_mock{ isOnReplyRouteSet = true, is_update = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_reply).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is onreply_route set for UPDATE", function()
    init_mock{ isOnReplyRouteSet = false, is_update = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_reply).was.called()
    assert.spy(core.exit).was.called()
  end)

  it("Is failure_route already set for INVITE", function()
    init_mock{ isFailureRouteSet = true, is_invite = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_failure).was.called(0)
    assert.spy(core.exit).was.called()
  end)
  it("Is failure_route set for INVITE", function()
    init_mock{ isFailureRouteSet = false, is_invite = true }
    actions.relay_message()
    assert.spy(KSR.tm.t_on_failure).was.called()
    assert.spy(core.exit).was.called()
  end)

  it("Error if relay target isn't set", function()
    init_mock{ relaySuccessful = false }
    actions.relay_message()
    assert.spy(reply.with_stateless_error_and_exit).was.called()
    assert.spy(core.exit).was.called()
  end)
  it("No error if relay target is set", function()
    init_mock{ relaySuccessful = true }
    actions.relay_message()
    assert.spy(reply.with_stateless_error_and_exit).was.called(0)
    assert.spy(core.exit).was.called()
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
