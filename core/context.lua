Roots.Context.p = createLuaFunc( function( context ) -- Context#p
	local args = context.callState.message.arguments
	local callingContext = context.callState.callingContext
	for i=1, #args do
		local theExpressionValue = eval( callingContext, callingContext, args[i] )
		print( toLuaString( theExpressionValue ) )
	end
	return Roots['nil']
end )

Roots.Context.method = createLuaFunc( function( context ) -- Context#method
	local theLastExpr = context.callState.message.arguments[ #context.callState.message.arguments ]
	local theFunc     = runtime.setInheritance( theLastExpr, Roots.Function )

	theFunc.namedArguments = sendMessageAsString( Roots.Array, 'new' )
	local theNumArgs = #context.callState.message.arguments-1
	for i=1,theNumArgs do
		theFunc.namedArguments[i] = context.callState.message.arguments[i][1][1].identifier
	end
	theFunc.creationContext = context.callState.callingContext

	return theFunc
end )

Roots.Context['while'] = createLuaFunc( function( context ) -- Context#while
	if #context.callState.message.arguments ~= 2 then
		error( "while requires 2 arguments" )
	end
	local conditionExpression = context.callState.message.arguments[ 1 ]
	local clauseExpression    = context.callState.message.arguments[ 2 ]
	local contextOfWhile      = context.self
	local condition           = eval( contextOfWhile, contextOfWhile, conditionExpression )
	local returnValue         = Roots['nil']
	while condition ~= Roots['nil'] and condition ~= Roots['false'] do
		returnValue = eval( contextOfWhile, contextOfWhile, clauseExpression )
		condition   = eval( contextOfWhile, contextOfWhile, conditionExpression )
	end
	return returnValue 
end )

Roots.Context['if'] = createLuaFunc( function( context ) -- Context#if
	local contextOfFunc	 = context.self
	local args           = context.callState.message.arguments
	local conditionValue = eval( contextOfFunc, contextOfFunc, args[ 1 ] )
	if conditionValue ~= Roots['nil'] and conditionValue ~= Roots['false'] then
		return eval( contextOfFunc, contextOfFunc, args[ 2 ] )
	else
		return eval( contextOfFunc, contextOfFunc, args[ 3 ] )
	end
end )

Roots.Context.toString = createLuaFunc( function( context ) -- Context#toString
	if context.self == Roots.Lawn or context.self == Roots.Context then
		return context.self.__name
	else
		return runtime.string[
			string.format( "<Context of '%s'>",
				runtime.luastring[ context.self.callState.message.identifier ]
			)
		]
	end
end )

Roots.Context.asCode = createLuaFunc( function( context ) -- Context#asCode
	if context.self == Roots.Lawn then
		return runtime.string[ string.format("%s (0x%04x)", "Lawn", runtime.ObjectId[ context.self ] ) ]
	elseif context.self == Roots.Context then
		return runtime.string[ string.format("%s (0x%04x)", "Context", runtime.ObjectId[ context.self ] ) ]
	else
		return runtime.string[
			string.format( "<Context of '%s' (0x%04x)>",
				runtime.luastring[ context.self.callState.message.identifier ],
				runtime.ObjectId[ context.self ]
			)
		]
	end
end )

