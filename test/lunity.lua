local setmetatable=setmetatable
local _G=_G
module( 'lunity' )
local lunity = _M
setmetatable( lunity, {
  __index = _G,
  __call = function( self, testSuite )
    setmetatable( testSuite, {
      __index = function( testSuite, value )
        if value == 'runTests' then
          return function() lunity.__runAllTests(testSuite) end
        elseif lunity[value] then
          return lunity[value]
        else
          return nil
        end
      end
    } )
  end
} )

function __assertionSucceeded()
  lunity.__assertsPassed = lunity.__assertsPassed + 1
  io.write('.')
  return true
end

function fail( msg )
  if not msg then msg = "(test failure)" end
  error( msg, 2 )
end

function assert( testCondition, msg )
  if not testCondition then
    if not msg then msg = "assert() failed: value was "..tostring(testCondition) end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertEqual( actual, expected, msg )
  if actual~=expected then
    if not msg then
      msg = string.format( "assertEqual() failed: expected %s, was %s",
        tostring(expected),
        tostring(actual)
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertNotEqual( actual, expected, msg )
  if actual==expected then
    if not msg then
      msg = string.format( "assertNotEqual() failed: value not allowed to be %s",
        tostring(actual)
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertTrue( actual, msg )
  if actual ~= true then
    if not msg then
      msg = string.format( "assertTrue() failed: value was %s, expected true",
        tostring(actual)
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertFalse( actual, msg )
  if actual ~= false then
    if not msg then
      msg = string.format( "assertFalse() failed: value was %s, expected false",
        tostring(actual)
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertNil( actual, msg )
  if actual ~= nil then
    if not msg then
      msg = string.format( "assertNil() failed: value was %s, expected nil",
        tostring(actual)
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertNotNil( actual, msg )
  if actual == nil then
    if not msg then msg = "assertNotNil() failed: value was nil" end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertType( actual, expectedType, msg )
  if type(actual) ~= expectedType then
    if not msg then
      msg = string.format( "assertType() failed: value %s is a %s, expected to be a %s",
        tostring(actual),
        type(actual),
        expectedType
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

-- Ensures that the value is a function OR may be called as one
function assertInvokable( value, msg )
  local meta = getmetatable(value)
  if (type(value) ~= 'function') or not (meta and meta.__call) then
    if not msg then
      msg = string.format( "assertInvokable() failed: value %s can not be called as a function",
        tostring(value)
      )
    end
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertErrors( invokable, ... )
  assertInvokable( invokable )
  if pcall(invokable,...) then
    local msg = string.format( "assertErrors() failed: %s did not raise an error",
      tostring(invokable)
    )
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function assertDoesNotError( invokable, ... )
  assertInvokable( invokable )
  if not pcall(invokable,...) then
    local msg = string.format( "assertDoesNotError() failed: %s raised an error",
      tostring(invokable)
    )
    error( msg, 2 )
  end
  return __assertionSucceeded()
end

function is_nil( value ) return type(value)=='nil' end
function is_boolean( value ) return type(value)=='boolean' end
function is_number( value ) return type(value)=='number' end
function is_string( value ) return type(value)=='string' end
function is_table( value ) return type(value)=='table' end
function is_function( value ) return type(value)=='function' end
function is_thread( value ) return type(value)=='thread' end
function is_userdata( value ) return type(value)=='userdata' end

function __runAllTests(testSuite)
  lunity.__assertsPassed = 0
  
  local theTestNames = {}
  for testName,test in pairs(testSuite) do
    if type(test)=='function' and type(testName)=='string' and (testName:find("^test") or testName:find("test$")) then
      theTestNames[#theTestNames+1] = testName
    end
  end
  table.sort(theTestNames)
  
  local theSuccessCount = 0
  for _,testName in ipairs(theTestNames) do
    local testScratchpad = {}
    io.write( testName..": " )
    if testSuite.setup then testSuite.setup(testScratchpad) end
    local successFlag, errorMessage = pcall( testSuite[testName], testScratchpad )
    if successFlag then
      print("pass")
      theSuccessCount = theSuccessCount + 1
    else
      print("FAIL!")
      print( errorMessage )
    end    
    if testSuite.teardown then testSuite.teardown( testScratchpad ) end
  end
  
  print( string.format(
    "%s\n%d/%d tests passed (%0.1f%%)\n%d total successful assertions",
    string.rep( '-', 78 ),
    theSuccessCount,
    #theTestNames,
    100 * theSuccessCount / #theTestNames,
    lunity.__assertsPassed,
    lunity.__assertsPassed == 1 and "" or "s"
  ) )  
end