Roots.Expression.new = createLuaFunc( function( context ) -- Expression#new
	-- Re-use existing expression created for the first chunk argument, if available
	local args = context.callState.message.arguments
	local expression = (#args > 0) and #args[1] or runtime.childFrom( Roots.Expression )
	expression.creationContext = context.callState.callingContext
	return expression
end )

Roots.Expression.appendMessage = Roots.Array.push

Roots.Expression.eval = createLuaFunc( 'evalContext', 'receiver', function( context ) -- Expression#eval
	-- Users may optionally specify an explicit context to evaluate in
	-- Expressions explicitly created (Expression new) have a creationContext
	if context.evalContext == Roots['nil'] then
		context.evalContext = context.self.creationContext
		if arg.debugLevel >= 2 then
			print( "No explicit context for Expression#eval; using "..tostring(context.evalContext) )
		end

		-- As a fallback, evaluate the expression in the context eval was called in
		if context.evalContext == Roots['nil'] then
			context.evalContext = context.callState.callingContext
			if arg.debugLevel >= 2 then
				print( "...and no creationContext, either; using "..tostring(evalContext) )
			end	
		end
	end
	
	if context.receiver == Roots['nil'] then
		context.receiver = context.evalContext
	end
	
	return evaluateExpression( context.evalContext, context.receiver, context.self )
end )

Roots.Expression.asCode = createLuaFunc( function( context ) -- Expression#asCode
	local theIntrinsicName = rawget( context.self, '__name' )
	if theIntrinsicName then
		return theIntrinsicName
	else
		local theMessagesCode = {}
		for i,message in ipairs(context.self) do
			theMessagesCode[i] = runtime.luastring[ sendMessageAsString( message, 'asCode' ) ]
		end
		if context.self.parent ~= Roots['nil'] then 
			return runtime.string[ table.concat( theMessagesCode, " " ) ]
		else
			return runtime.string[ table.concat( theMessagesCode, "\n" ) ]
		end
	end
end )

Roots.Expression.toString = createLuaFunc( function( context ) -- Expression#toString
	local theIntrinsicName = rawget( context.self, '__name' )
	if theIntrinsicName then
		return runtime.string[ string.format("%s (0x%04x)", runtime.luastring[theIntrinsicName], runtime.ObjectId[context.self] ) ]
	else		
		local theMessagesCode = {}
		for i,message in ipairs(context.self) do
			theMessagesCode[i] = runtime.luastring[ sendMessageAsString( message, 'asCode' ) ]
		end
		return runtime.string[
			string.format( "<%s : %s : (0x%04x)>",
				runtime.luastring[context.self.__name],
				table.concat( theMessagesCode, " " ),
				runtime.ObjectId[context.self]
			)
		]
	end
end )

