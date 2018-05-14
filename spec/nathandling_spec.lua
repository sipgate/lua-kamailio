require 'busted.runner'()

local function init_mock(options)
  -- mock global variable 'KSR'
  local ksr_mock = {
    pv = {
      get = function(key)
        if key == "$rU" then
          if options.rU ~= nil then return options.rU else return "01234567" end
        end
      end,
      sets = function(k, v) end,
    },
    hdr = {
      append = function(header) end,
    },
    nathelper = {
      nat_uac_test = function(flags) return options.is_nated end,
      fix_nated_register = function() end,
      set_contact_alias = function() end,
    },
    setflag = function(flag) end,
  }
  _G["KSR"] = mock(ksr_mock)
  
  local message_mock = {
    is_register = function() return options.is_register end,
    is_first_hop = function() return options.is_first_hop end
  }
  _G["message"] = mock(message_mock)
end

local nathandling = require "kamailio/nathandling"

describe("Check for caller NAT -> ", function()
  it("Detect NAT REGISTER", function()
    init_mock{ is_register = true, is_nated = 1 }
    nated = nathandling.detect_caller_nat()
    assert.are.equal(1, nated)
    assert.spy(KSR.nathelper.nat_uac_test).was.called_with(19)
    assert.spy(KSR.nathelper.fix_nated_register).was.called()
    assert.spy(KSR.nathelper.set_contact_alias).was.called(0)
    assert.spy(KSR.setflag).was.called()
  end)
  it("Detect non-NAT REGISTER", function()
    init_mock{ is_register = true, is_nated = 0 }
    nated = nathandling.detect_caller_nat()
    assert.are.equal(nil, nated)
    assert.spy(KSR.nathelper.nat_uac_test).was.called_with(19)
    assert.spy(KSR.nathelper.fix_nated_register).was.called(0)
    assert.spy(KSR.nathelper.set_contact_alias).was.called(0)
    assert.spy(KSR.setflag).was.called(0)
  end)
  it("Detect NAT INVITE, first hop", function()
    init_mock{ is_register = false, is_nated = 1, is_first_hop = true }
    nated = nathandling.detect_caller_nat()
    assert.are.equal(1, nated)
    assert.spy(KSR.nathelper.nat_uac_test).was.called_with(19)
    assert.spy(KSR.nathelper.fix_nated_register).was.called(0)
    assert.spy(KSR.nathelper.set_contact_alias).was.called()
    assert.spy(KSR.setflag).was.called()
  end)
  it("Detect NAT INVITE, not first hop", function()
    init_mock{ is_register = false, is_nated = 1, is_first_hop = false }
    nated = nathandling.detect_caller_nat()
    assert.are.equal(1, nated)
    assert.spy(KSR.nathelper.nat_uac_test).was.called_with(19)
    assert.spy(KSR.nathelper.fix_nated_register).was.called(0)
    assert.spy(KSR.nathelper.set_contact_alias).was.called(0)
    assert.spy(KSR.setflag).was.called()
  end)
  it("Detect non-NAT INVITE, first hop", function()
    init_mock{ is_register = false, is_nated = 0, is_first_hop = true }
    nated = nathandling.detect_caller_nat()
    assert.are.equal(nil, nated)
    assert.spy(KSR.nathelper.nat_uac_test).was.called_with(19)
    assert.spy(KSR.nathelper.fix_nated_register).was.called(0)
    assert.spy(KSR.nathelper.set_contact_alias).was.called(0)
    assert.spy(KSR.setflag).was.called(0)
  end)
end)