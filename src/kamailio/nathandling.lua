-- Everything with NAT
message = require "kamailio.message"
core = require "kamailio.core"

local nathandling = {
}

-- Getter/Setter, don't test

-- Local functions
local function set_nat_flag()
  core.set_flag(FLT_NATS)
end

-- Public functions

function nathandling.force_rport()
  KSR.force_rport()
end

-- Testworthy methods here

-- Tested
function nathandling.detect_caller_nat()
  if KSR.nathelper.nat_uac_test(19)>0 then
    if message.is_register() then
      KSR.nathelper.fix_nated_register()
    elseif message.is_first_hop() then
      KSR.nathelper.set_contact_alias()
    end
    set_nat_flag()
    return 1
  end
end


return nathandling