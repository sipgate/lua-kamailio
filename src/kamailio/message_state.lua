local message_state = {}

function message_state.has_transaction()
  return KSR.tm.t_check_trans() > 0
end

function message_state.check_for_active_transaction()
  return KSR.tm.t_check_trans()
end

function message_state.is_handled_by_another_process()
  return KSR.tmx.t_precheck_trans() > 0
end

return message_state