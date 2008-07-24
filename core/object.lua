Roots.Object.new = createLuaFunc( function( context ) -- Object#new
	return runtime.childFrom( context.self )
end )

Roots.Object.setSlot = createLuaFunc( 'slotName', 'slotValue', function( context ) -- Object#setSlot
	-- TODO: get via messages?
	-- TODO: what about non-string slots? And should string objects be indexed by that table or the string?
	local slotName = toLuaString( context.slotName )
	context.self[ slotName ] = context.slotValue
	return context.slotValue
end )

Roots.Object.getSlot = createLuaFunc( 'slotName', function( context ) -- Object#getSlot
	-- TODO: get via messages?
	-- TODO: should I really be casting to a string always? 
	local slotName = toLuaString( context.slotName )
	return context.self[ slotName ] or Roots['nil']
end )

Roots.Object.id = createLuaFunc( function( context ) -- Object#id
	return runtime.number[ runtime.ObjectId[ context.self ] ]
end )

Roots.Object.self = createLuaFunc( function( context ) -- Object#self
	return context.self
end )

Roots.Object['=='] = createLuaFunc( 'obj2', function( context ) -- Object#==
	local rvalue = context.obj2
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Object#== is mising a comparator" )
		end
	end
	
	return ( context.self == rvalue ) and Roots['true'] or Roots['false']
end )

Roots.Object.toString = createLuaFunc( function( context ) -- Object#toString
	local theIntrinsicName = rawget(context.self, "__name")
	if theIntrinsicName then
		return theIntrinsicName
	else
		return runtime.string[ string.format( "<%s instance>", runtime.luastring[ context.self.__name ] ) ]
	end
end )

Roots.Object.asCode = createLuaFunc( function( context ) -- Object#asCode
	local theIntrinsicName = rawget(context.self, "__name")
	if theIntrinsicName then
		return runtime.string[ string.format("%s (0x%04x)", runtime.luastring[theIntrinsicName], runtime.ObjectId[ context.self ] ) ]
	else
		return runtime.string[ string.format( "<%s instance (0x%04x)>", runtime.luastring[ context.self.__name ], runtime.ObjectId[ context.self ] ) ]
	end
end )

Roots.Object['or'] = createLuaFunc ( function( context ) -- Object#or
	return context.self
end )
