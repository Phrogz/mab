require 'test/lunity'

module( 'TEST_ACCEPTANCE', lunity )

tests = {
	"01a_hello_world",
	"02_this_is_hot",
	"02b_debugEval",
	"03_beer",
	"04_simple_method",
	"05_toString_override",
	"06_contexts",
	"07_simple_add",
	"07b_add_no_parens",
	"08a_newton_ugly",
	"08c_newton_pretty",
	"10a_dynamic_expression",
	"10b_appendMessage",
	"10c_dynamicMessage",
	"11_eval",
	"12_program",
	"13_sieve",
	"13b_arraySieve",
	"14_changeMaker",
	"14b_changeMaker_simple",
	"14c_changeMaker_with_operators",
	"15_ObjectScope",
	"15b_SubtleObjectScope",
	"16_locals_shadow_context",
	"17_scope_resolution",
	"17b_lexical_scope",
	"18_subexpressions"
}

function setup()
	require 'parser'
	
	runtime.stdout = ""
	core.Roots.Context.p = core.createLuaFunc( function( context )
		local args = context.callState.message.arguments
		for i=1, #args do
			local theValue = core.eval( context.callState.callingContext, context.callState.callingContext, args[i] )
			runtime.stdout = runtime.stdout .. runtime.luastring[ theValue ] .. "\n"
		end
		return core.Roots['nil']
	end )

end

function teardown()
package.loaded.parser  = nil
package.loaded.core    = nil
package.loaded.runtime = nil
end

function makeAcceptance( testName )
	return function()
		io.input( "test/acceptance/".. testName..".mab" )
		local code = io.read("*a")
			
		io.input( "test/acceptance/".. testName..".expected" )
		local expected = io.read("*a")
		local expectedLines = {}
		for line in string.gmatch( expected, "[^\n\r]+") do
			table.insert( expectedLines, line )
		end

		parser.runString( code )

		local actualLines = {}
		for line in string.gmatch( runtime.stdout, "[^\n\r]+") do
			table.insert( actualLines, line )
		end

		for i,expectedLine in ipairs(expectedLines) do
			assertEqual( actualLines[i], expectedLine, string.format( "output line #%d\n  expected: %s\n       was: %s", i, expectedLine, tostring(actualLines[i])) )
		end
	end
end

for i,testName in ipairs(tests) do
	_M["test"..testName] = makeAcceptance( testName )
end


runTests()