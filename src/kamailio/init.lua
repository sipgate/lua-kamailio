-- This is a sample Kamailio functions file
-- Use it at your own risk
actions = require "kamailio.actions"
core = require "kamailio.core"
headers = require "kamailio.headers"
message = require "kamailio.message"
message_state = require "kamailio.message_state"
nathandling = require "kamailio.nathandling"
security = require "kamailio.security"
traffic = require "kamailio.traffic"


local kamailio = {}

function kamailio:process_request()

  -- per request initial checks
  do_prechecks()

  detect_nat()

  -- CANCEL processing
  if message.is_cancel() then
    if message_state.has_transaction() then
      actions.relay_message()
    end
    return 1;
  end

  handle_in_dialog_requests()
  
  -- handle retransmissions
  if message_state.is_handled_by_another_process() then
    message_state.check_for_active_transaction()
    return 1;
  end
  if message_state.check_for_active_transaction() == 0 then return 1 end

  authorize_request()

	-- record routing for dialog forming requests (in case they are routed)
	-- - remove preloaded route headers
  headers.remove_header("Route")
  if message.is_invite() or message.is_subscribe() then
    headers.add_record_route()
  end

  -- account only INVITEs
  if message.is_invite() then
    core.set_flag(FLT_ACC) -- do accounting
  end

  -- dispatch requests to foreign domains
  route_to_foreign_domains()

	-- -- requests for my local domains

  -- handle registrations
  handle_registers()

  --- TODO: Left off here
  if message.has_empty_request_user() then
    -- request with no Username in RURI
    reply.with_stateless_484_and_exit()
  end

  -- user location service
  actions.route_to_location()

  return 1;

end

function handle_registers()
  if not message.is_register() then return 1 end
  if core.is_flagset(FLT_NATS) then
    core.set_branch_flag(FLB_NATB)
    -- do SIP NAT pinging
    core.set_branch_flag(FLB_NATSIPPING)
  end
  actions.save_register()
  core.exit()
end

function route_to_foreign_domains()
  if message.is_request_to_local_request_domain() then return 1 end
  headers.append_header("P-Hint", "outbound")
  actions.relay_message()
  core.exit()
end

-- IP authorization and user uthentication
function authorize_request()

  if message.is_register() then
    if security.is_allowed_by_permissions() then
      -- source IP allowed
      return 1;
    end
  end
  if message.is_register() or message.is_request_from_local_from_domain() then
    -- authenticate requests
    if security.is_not_authenticated() then
      security.send_auth_chalenge()
      core.exit()
    end
    -- user authenticated - remove auth header
    if not (message.is_register() or message.is_publish()) then
      security.remove_credentials()
    end
  end

  -- if caller is not local subscriber, then check if it calls
  -- a local destination, otherwise deny, not an open relay here
  if (not message.is_request_from_local_from_domain())
      and (not message.is_request_to_local_request_domain()) then
    reply.with_stateless_403_and_exit()
  end

  return 1;
end


-- Handle requests within SIP dialogs
function handle_in_dialog_requests()
	if not message.has_to_tag() then return 1; end

	-- sequential request withing a dialog should
	-- take the path determined by record-routing
  -- TODO: Masquerade some more functions
	if KSR.rr.loose_route()>0 then
		ksr_route_dlguri();
		if message.is_bye() then
			KSR.setflag(FLT_ACC); -- do accounting ...
			KSR.setflag(FLT_ACCFAILED); -- ... even if the transaction fails
		elseif message.is_ack() then
			-- ACK is forwarded statelessly
			ksr_route_natmanage();
		elseif message.is_notify() then
			-- Add Record-Route for in-dialog NOTIFY as per RFC 6665.
			headers.add_record_route()
		end
    actions.relay_message()
		core.exit()
	end
	if message.is_ack() then
		if message_state.has_transaction() then
			-- no loose-route, but stateful ACK;
			-- must be an ACK after a 487
			-- or e.g. 404 from upstream server
      actions.relay_message()
  		core.exit()
		else
			-- ACK without matching transaction ... ignore and discard
  		core.exit()
		end
	end
  reply.with_stateless_404_and_exit()
end


function do_prechecks()
  if not traffic.is_request_from_local() then
    if security.is_ip_banned() then
      -- ip is already blocked
      KSR.dbg("request from blocked IP - " .. KSR.pv.get("$rm")
      .. " from " .. KSR.pv.get("$fu") .. " (IP:"
      .. KSR.pv.get("$si") .. ":" .. KSR.pv.get("$sp") .. ")\n");
      core.exit()
    end
    if security.pike_above_limit() then
      KSR.err("ALERT: pike blocking " .. KSR.pv.get("$rm")
      .. " from " .. KSR.pv.get("$fu") .. " (IP:"
      .. KSR.pv.get("$si") .. ":" .. KSR.pv.get("$sp") .. ")\n");
      security.ban_ip()
      core.exit()
    end
  end
  if message.is_from_bad_user_agent() then
    reply.with_stateless_200_and_exit()
  end

  actions.reject_looping_requests()

  actions.handle_options()

  actions.check_sanity()
end

-- Caller NAT detection
function detect_nat()
	nathandling.force_rport()
  nathandling.detect_caller_nat()
  return 1
end



return kamailio