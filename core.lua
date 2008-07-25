require 'runtime'
module( 'core', package.seeall )

function createExpression( creationContext )
	local expression = runtime.childFrom( Roots.Expression )
	expression.creationContext = creationContext or Roots.Lawn
	return expression
end

function createMessage( messageString, ... )
	local message = runtime.childFrom( Roots.Message )
	message.identifier = runtime.string[messageString]
	message.arguments = runtime.childFrom( Roots.ArgList )
	if select('#',...) > 0 then
		addChildren( message.arguments, ... )
	end
	return message
end

function addChildren( parent, ... )
	for i=1,select('#',...) do
		local child = select(i,...)
		local index = #parent + 1
		parent[index] = child
		child.parent  = parent
		if index > 1 then
			parent[index-1].next = child
			child.previous       = parent[index-1]
		end
	end
	return parent
end

function createLuaFunc( ... )
	local func = runtime.childFrom( Roots.Function )
	
	-- FIXME: sendMessageAsString( Roots.Array, 'new' ) fails; perhaps too soon?
	func.namedArguments = runtime.childFrom( Roots.Array )

	local theNumArgs = select('#',...) - 1
	for i=1,theNumArgs do
		local theArgName = select(i,...)
		-- TODO: remove check for speed?
		if type(theArgName)~="string" then
			error( "Argument #"..i.." to createLuaFunc() is "..tostring(theArgName))
		end
		func.namedArguments[i] = runtime.string[theArgName]
	end

	local theFunction = select(theNumArgs+1,...)
	if type(theFunction)~="function" then
		-- TODO: remove for speed
		error( "Final argument to createLuaFunc() is not a function (it is a "..tostring(theFunction)..")" )
	end

	func.__luaFunction = theFunction
	return func
end

-- ##########################################################################

function eval( context, receiver, expressionOrMessageOrLiteral, depth )
	if not depth then depth = 0 end
	local depthIndent = string.rep( "  ", depth )
	
	local returnValue
	if runtime.isKindOf( expressionOrMessageOrLiteral, Roots.Expression ) then
		print( string.format("%seval expression: 0x%04x", depthIndent, runtime.ObjectId[expressionOrMessageOrLiteral]))
		local expression = expressionOrMessageOrLiteral
		if expression.__luaFunction ~= Roots['nil'] then
			print( string.format("%seval expression as lua code", depthIndent))
			returnValue = expression.__luaFunction( context )
			if returnValue == nil then
				returnValue = Roots['nil']
				print( depthIndent.."This Lua function returned nil: "..tostring(expression.__luaFunction) )
			elseif returnValue == false then
				returnValue = Roots['nil']
				print( depthIndent.."This Lua function returned false: "..tostring(expression.__luaFunction) )
			else
				print( depthIndent.."Yay, the lua code returned something good")
			end
			print( string.format("%seval expression done", depthIndent))
			
		else
			print( string.format("%seval expression as collection", depthIndent))
			if context.evalStack == Roots['nil'] then
				context.evalStack = runtime.childFrom( Roots.Array )
			end

			local evalStackLevel = #context.evalStack + 1
			context.evalStack[ evalStackLevel ] = expression[1]

			local theCurrentObject
			while context.evalStack[ evalStackLevel ] ~= Roots['nil'] do
				theCurrentObject = context.evalStack[ evalStackLevel ]
				context.evalStack[ evalStackLevel ] = theCurrentObject.next
				receiver = eval( context, receiver, theCurrentObject, depth+1 ) or Roots['nil']
			end

			context.evalStack[ evalStackLevel ] = nil
			returnValue = receiver
		end
		
	elseif runtime.isKindOf( expressionOrMessageOrLiteral, Roots.Message ) then
		print( string.format("%seval message: 0x%04x", depthIndent, runtime.ObjectId[expressionOrMessageOrLiteral]))
		local message     = expressionOrMessageOrLiteral
		local messageName = runtime.luastring[ message.identifier ]
		local returnValue = receiver[ messageName ]

		if returnValue == Roots['nil'] and messageName ~= 'nil' then
			-- TODO: method_mising
			if arg.debugLevel >= 1 then
				print( "Warning: Cannot find message '"..tostring(messageName).."' on "..tostring(receiver))
			end
			
		elseif returnValue.executeOnAccess ~= Roots['nil'] then
			print( depthIndent..'eval message yielded function' )
			local functionObject = returnValue
			local executionContext = runtime.childFrom( functionObject.creationContext or Roots.Lawn )
			executionContext.self = receiver
			executionContext.callState = runtime.childFrom( Roots.CallState )
			executionContext.callState.target  = receiver
			executionContext.callState.message = message
			executionContext.callState.context = executionContext
			executionContext.callState['function'] = functionObject
			executionContext.callState.callingContext = context

			-- Setup local parameters; TODO: syntax/convention to allow eval of chunk params to be optional
			local theNextMessageInCallingContext = context.evalStack[ #context.evalStack ]
			for i=1,#functionObject.namedArguments do
				local theArgName = runtime.luastring[ functionObject.namedArguments[i] ]
				if arg.debugLevel >= 2 and rawget( executionContext, theArgName ) then
					print( "Warning: overriding built in context property '"..theArgName.."'" )
				end
				if message.arguments[i] ~= Roots['nil'] then
					executionContext[ theArgName ] = eval( context, context, message.arguments[i], depth+1 )
				else
					if arg.debugLevel >= 3 then
						print( "Warning: No argument passed for parameter '"..theArgName.."'; setting to Roots.nil" )
					end
					executionContext[ theArgName ] = Roots['nil']
				end
			end
			context.evalStack[ #context.evalStack ] = theNextMessageInCallingContext

			print( depthIndent..'about to call function' )
			returnValue = eval( executionContext, executionContext, functionObject, depth+1 )
			print( depthIndent..'done calling function' )
		end

	else -- Presumably this is a literal
		print( string.format("%seval literal: 0x%04x", depthIndent, runtime.ObjectId[expressionOrMessageOrLiteral]))
		returnValue = expressionOrMessageOrLiteral
		-- if arg.debugLevel >= 1 and not runtime.isKindOf( receiver, Roots.Context ) then
		-- 	print( "Warning: Literal value '"..tostring(literal).."' sent to non-context: "..tostring(receiver))
		-- end
	end
	
	if returnValue == nil then
		print( depthIndent.."WTF, it's NIL!" )
	elseif returnValue == false then
		print( depthIndent.."WTF, it's FALSE!" )
	elseif returnValue == Roots['nil'] then
		print( depthIndent.."OK, it's Roots.NIL!" )
	else
		print( depthIndent.."GOOD VALUE" )
	end
	
	return returnValue
end

-- function evaluateExpression( context, initialReceiver, expression )
-- 	if expression.__luaFunction ~= Roots['nil'] then
-- 		return expression.__luaFunction( context ) or Roots['nil']
-- 	else
-- 		local receiver = initialReceiver
-- 		if context.evalStack == Roots['nil'] then
-- 			context.evalStack = runtime.childFrom( Roots.Array )
-- 		end
-- 
-- 		local evalStackLevel = #context.evalStack + 1
-- 		context.evalStack[ evalStackLevel ] = expression[1]
-- 
-- 		while context.evalStack[ evalStackLevel ] ~= Roots['nil'] do
-- 			local theCurrentObj = context.evalStack[ evalStackLevel ]
-- 			context.evalStack[ evalStackLevel ] = theCurrentObj.next
-- 			receiver = eval( context, receiver, theCurrentObj )
-- 		end
-- 
-- 		context.evalStack[ evalStackLevel ] = nil
-- 		return receiver
-- 	end
-- end

-- function sendMessage( callingContext, receiver, messageOrLiteral )
-- 	local messageName = runtime.luastring[ messageOrLiteral.identifier ]
-- 	local obj = receiver[ messageName ]
-- 
-- 	if obj == Roots['nil'] and messageName ~= 'nil' then
-- 		-- TODO: method_mising
-- 		-- FIXME: No need to error, just flow through to return Roots.nil
-- 		if arg.debugLevel >= 1 then
-- 			print( "Warning: Cannot find message '"..tostring(messageName).."' on "..tostring(receiver) )
-- 		end
-- 	elseif obj.executeOnAccess ~= Roots['nil'] then
-- 		obj = executeFunction( obj, receiver, messageOrLiteral, callingContext )
-- 	end
-- 
-- 	return obj or Roots['nil']
-- end

-- function executeFunction( functionObject, receiver, message, callingContext )
-- 	if callingContext == Roots['nil'] then
-- 		if arg.debugLevel >= 2 then
-- 			local messageString = runtime.luastring[message.identifier]
-- 			if messageString ~= 'toString' and messageString ~= 'asCode' then
-- 				print( "Warning: No message/expression context when sending '"..messageString.."'...so I'm using the Lawn instead." )
-- 			end
-- 		end
-- 		callingContext = Roots.Lawn
-- 	end
-- 
-- 	local context = runtime.childFrom( functionObject.creationContext or Roots.Lawn )
-- 	context.self = receiver
-- 	context.callState = runtime.childFrom( Roots.CallState )
-- 	context.callState.target  = receiver
-- 	context.callState.message = message
-- 	context.callState.context = context
-- 	context.callState['function'] = functionObject
-- 	context.callState.callingContext = callingContext
-- 
-- 	-- Setup local parameters
-- 	-- TODO: syntax to allow eval of chunks to be optional
-- 	if functionObject.namedArguments ~= Roots['nil'] then
-- 		local theNextMessageInCallingContext = callingContext.evalStack[ #callingContext.evalStack ]
-- 		for i=1,#functionObject.namedArguments do
-- 			local theArgName = runtime.luastring[ functionObject.namedArguments[i] ]
-- 			if arg.debugLevel >= 2 and rawget( context, theArgName ) then
-- 				print( "Warning: overriding built in context property '"..theArgName.."'" )
-- 			end
-- 			if message.arguments[i] ~= Roots['nil'] then
-- 				context[ theArgName ] = eval( callingContext, callingContext, message.arguments[i] )
-- 			else
-- 				if arg.debugLevel >= 3 then
-- 					print( "Warning: No argument passed for parameter '"..theArgName.."'; setting to Roots.nil" )
-- 				end
-- 				context[ theArgName ] = Roots['nil']
-- 			end
-- 		end
-- 		callingContext.evalStack[ #callingContext.evalStack ] = theNextMessageInCallingContext
-- 	end
-- 
-- 	return evaluateExpression( context, context, functionObject )
-- end

-- ##########################################################################

-- Cache for simple no-argument messages sent from Lua, indexed by message identifier
messageCache = {}
setmetatable( messageCache, {
	__index = function( t, messageString )
		local theMessage = createMessage( messageString )
		t[ messageString ] = theMessage
		return theMessage
	end
} )

function sendMessageAsString( object, messageString, ... )
	local message
	if select('#',...) == 0 then
		message = messageCache[messageString]
	else
		-- Assume each argument to the message is already a simple Mab object
		message = createMessage( messageString, ... )
	end
	
	return eval( Roots.Lawn, object, message )
end

-- ##########################################################################

function toObjString( object )
	if object == String then
		object = object.__name
	elseif not runtime.isKindOf( object, String ) then
		-- TODO: Perhaps replace test with a simple runtime.luastring[object], since every string object should have an entry here
		object = sendMessage( Roots.Lawn , object, messageCache['toString'] )
	end
	-- TODO: Perhaps replace test with a simple runtime.luastring[object], since every string object should have an entry here
	if runtime.isKindOf( object, String ) then
		return object
	else
		error( "toString returned something other than a String object ("..type(object)..")" )
	end
end

-- ##########################################################################

function slurpNextValue( callState )
	local theNextValue = callState.message.next
	if theNextValue ~= Roots['nil'] then
		local evalStack = callState.callingContext.evalStack
		evalStack[ #evalStack ] = theNextValue.next
		theNextValue = eval( callState.callingContext, callState.callingContext, theNextValue )
	end
	return theNextValue
end

-- ##########################################################################

-- TODO: remove this debug function (or more to debug utils, callState.callingContext, theNextValue )
function printObjectAsXML( object, showReferenced, depth, recursingFlag )
	if not depth then depth = 0 end

	if not recursingFlag then
		_G.objectsPrinted = {}
	end

	local indent = string.rep( "  ", depth )

	if runtime.luanumber[ object ] then
		print( indent.."(N)"..runtime.luanumber[ object ] )

	elseif runtime.luastring[ object ] then
		print( indent.."(S)"..string.sub( string.format("%q",runtime.luastring[object]), 2, -2 ) )

	else
		local attrs = {}
		for attrName,attrObj in pairs(object) do
			if not tonumber( attrName ) then
				local valueString = (runtime.luanumber[ attrObj ] and ("(N)"..runtime.luanumber[attrObj])) or
				                    (runtime.luastring[ attrObj ] and ("(S)"..string.sub( string.format("%q",runtime.luastring[attrObj]), 2, -2 ) ) ) or
				                    ( runtime.ObjectId[ attrObj ] and string.format( "0x%04x", runtime.ObjectId[ attrObj ] ) ) or
				                    tostring( attrObj )
				attrs[ attrName ] = valueString
			end
		end
		local objectName = runtime.luastring[ object.__name ]
		if objectName == "Lawn" and object ~= Roots.Lawn then
			objectName = "Context"
		end
		io.write( string.format( '%s<%s id="0x%04x"', indent, objectName, runtime.ObjectId[ object ] ) )
		for attrName,valueString in pairs(attrs) do
			io.write( " "..attrName..'="'..valueString..'"' )
		end

		local objectShowingChildren = object
		if runtime.isKindOf( object.arguments, Roots.ArgList ) then
			objectShowingChildren = object.arguments
			_G.objectsPrinted[ object.arguments ] = true
		end

		if #objectShowingChildren > 0 then
			print( ">" )
			for _,childObj in ipairs(objectShowingChildren) do
				printObjectAsXML( childObj, showReferenced, depth+1, true )
			end
			print( indent.."</"..runtime.luastring[ object.__name ]..">" )
		else
			print( " />" )
		end
	end

	_G.objectsPrinted[ object ] = true

	if showReferenced and not recursingFlag then
		print( "<!-- ############### Referenced Objects ############### -->" )
		for id,object in ipairs(runtime.ObjectById) do
			if not _G.objectsPrinted[ object ] and not runtime.luastring[ object ] and not runtime.luanumber[ object ] then
				printObjectAsXML( object, showReferenced, 0, true )
			end
		end
	end
end

-- ##########################################################################

-- TODO: replace with uber-portable directory scan
lua_files = {
	"1a_basics.lua",
	"arglist.lua",
	"array.lua",
	"boolean.lua",
	"callstate.lua",
	"context.lua",
	"expression.lua",
	"function.lua",
	"lawn.lua",
	"message.lua",
	"number.lua",
	"object.lua",
	"ornaments.lua",
	"roots.lua",
	"string.lua",
	"zz_finish.lua"
}

for _,fileName in ipairs(lua_files) do
	local fileChunk = loadfile( "core/" .. fileName )
	setfenv( fileChunk, _M )
	fileChunk( )
end

