-- Message functions
local message = {
}

-- Getter/Setter, don't test

function message.get_useragent()
  return KSR.pv.get("$ua")
end

function message.get_type()
  return KSR.pv.get("$rm")
end

function message.has_empty_request_user()
  return KSR.pv.is_null("$rU")
end

function message.is_ack()
  return message.get_type() == "ACK"
end

function message.is_bye()
  return message.get_type() == "BYE"
end

function message.is_cancel()
  return message.get_type() == "CANCEL"
end

function message.is_invite()
  return message.get_type() == "INVITE"
end

function message.is_notify()
  return message.get_type() == "NOTIFY"
end

function message.is_options()
  return message.get_type() == "OPTIONS"
end

function message.is_register()
  return message.get_type() == "REGISTER"
end

function message.is_subscribe()
  return message.get_type() == "BYE"
end

function message.is_update()
  return message.get_type() == "UPDATE"
end

function message.is_request_to_local_request_domain()
  return KSR.is_myself(KSR.pv.get("$ru"))
end

function message.is_request_from_local_from_domain()
  return KSR.is_myself(KSR.pv.get("$fu"))
end

function message.is_first_hop()
  return KSR.siputils.is_first_hop()>0
end

function message.has_to_tag()
  return KSR.siputils.has_totag()>0
end

function message.create_transaction()
  KSR.tm.t_newtran()
end

-- Testworthy methods here

-- Tested
function message.is_from_bad_user_agent()
  ua = message.get_useragent()
  return (ua ~= nil)
    and (string.find(ua, "friendly%-scanner")
    or string.find(ua, "sipcli"))
end

return message