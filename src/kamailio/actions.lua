-- Define your actions here
message = require "kamailio.message"
core = require "kamailio.core"
reply = require "kamailio.reply"

local actions = {}

function actions.save_register()
  if KSR.registrar.save("location", 0)<0 then
    reply.with_stateless_error_and_exit()
  end
end

function actions.reject_looping_requests()
  if KSR.maxfwd.process_maxfwd(10) < 0 then
    reply.stateless(483, "Too Many Hops")
    core.exit()
  end
end

function actions.handle_options()
  if message.is_options()
  and message.is_request_to_local_request_domain()
  and message.has_empty_request_user() then
    reply.stateless(200, "Keepalive")
    core.exit()
  end
end

function actions.check_sanity()
  if KSR.sanity.sanity_check(1511, 7)<0 then
    KSR.err("Malformed SIP message from "
    .. KSR.pv.get("$si") .. ":" .. KSR.pv.get("$sp") .."\n");
    core.exit()
  end
end

-- wrapper around tm relay function
function actions.relay_message()
  -- enable additional event routes for forwarded requests
  -- - serial forking, RTP relaying handling, a.s.o.
  if message.is_invite() or message.is_bye()
    or message.is_subscribe() or message.is_update() then
    if KSR.tm.t_is_set("branch_route")<0 then
      KSR.tm.t_on_branch("ksr_branch_manage");
    end
  end
  if message.is_invite() or message.is_subscribe()
    or message.is_update() then
    if KSR.tm.t_is_set("onreply_route")<0 then
      KSR.tm.t_on_reply("ksr_onreply_manage");
    end
  end

  if message.is_invite() then
    if KSR.tm.t_is_set("failure_route")<0 then
      KSR.tm.t_on_failure("ksr_failure_manage");
    end
  end

  if KSR.tm.t_relay()<0 then
    reply.with_stateless_error_and_exit()
  end
  core.exit();
end

function actions.route_to_location()
  local rc = KSR.registrar.lookup("location")
  if rc<0 then
    message.create_transaction()
    if rc==-1 or rc==-3 then
      reply.with_stateful_404_and_exit()
    elseif rc==-2 then
      reply.with_stateless_405_and_exit()
    end
  end

  -- when routing via usrloc, log the missed calls also
  if message.is_invite() then
    core.set_flag(FLT_ACCMISSED)
  end

  actions.relay_message()
  core.exit()

end

return actions
