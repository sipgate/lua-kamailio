-- Functions working with headers
rex = require "rex_pcre"
message = require "kamailio.message"

local headers = {}

function headers.get_request_user()
  return KSR.pv.get("$rU")
end

function headers.set_request_user(value)
  KSR.pv.sets("$rU", value)
end

function headers.append_header(header, value)
  if header == nil then return nil end
  KSR.hdr.append(header..": "..value.."\r\n")
end

function headers.remove_header(header)
  if header == nil then
    return false
  end
  KSR.hdr.remove(header)
end

function headers.add_record_route()
  KSR.rr.record_route()
end

function headers.suppress_cid_if_needed()
  request_user = headers.get_request_user()
  if rex.find(request_user, "^\\*31([*#]|%23)?") then
    headers.set_request_user(rex.gsub(request_user, "^\\*31([*#]|%23)?", ""))
    if message.is_invite() then headers.append_header("Privacy", "id") end
  end
end

return headers