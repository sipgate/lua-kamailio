local core = {}

function core.exit()
  KSR.x.exit()
end

function core.set_flag(flag)
  KSR.setflag(flag)
end

function core.set_branch_flag(flag)
  KSR.setbflag(flag)
end

function core.is_flag_set(flag)
  return KSR.isflagset(flag)
end

function core.is_branch_flag_set(flag)
    return KSR.isbflagset(flag)
end

return core
