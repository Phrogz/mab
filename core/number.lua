Roots.Number = runtime.childFrom( Roots.Object, "Number" )

runtime.number		= {}
runtime.luanumber = {}
setmetatable( runtime.number, {
	__index = function( self, value )
		local numberObject = runtime.childFrom( Roots.Number )
		self[ value ] = numberObject
		runtime.luanumber[ numberObject ] = value
		return numberObject
	end
} )

Roots.Number['+'] = createLuaFunc( 'addend', function( context ) -- Number#+
	local lvalue = runtime.luanumber[ context.self ]
	local rvalue = runtime.luanumber[ context.addend ]
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Number#+ is mising an addend" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end
	return runtime.number[ lvalue + rvalue ]
end )

Roots.Number['-'] = createLuaFunc( 'subtrahend', function( context ) -- Number#-
	local lvalue = runtime.luanumber[ context.self ]
	local rvalue = runtime.luanumber[ context.subtrahend ]
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Number#- is mising a subtrahend" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end
	return runtime.number[ lvalue - rvalue ]
end )

Roots.Number['>'] = createLuaFunc( 'rvalue', function( context ) -- Number#>
	local lvalue = runtime.luanumber[ context.self ]
	local rvalue = runtime.luanumber[ context.rvalue ]
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Number#> is mising an rvalue" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end
	return (lvalue > rvalue) and Roots['true'] or Roots['false']
end )

Roots.Number['<'] = createLuaFunc( 'rvalue', function( context ) -- Number#<
	local lvalue = runtime.luanumber[ context.self ]
	local rvalue = runtime.luanumber[ context.rvalue ]
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Number#< is mising an rvalue" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end
	return (lvalue < rvalue) and Roots['true'] or Roots['false']
end )

Roots.Number['*'] = createLuaFunc( 'multiplicand', function( context ) -- Number#*
	local lvalue = runtime.luanumber[ context.self ]
	local rvalue = runtime.luanumber[ context.multiplicand ]
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Number#* is mising a multiplicand" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end
	return runtime.number[ lvalue * rvalue ]
end )

Roots.Number['/'] = createLuaFunc( 'divisor', function( context ) -- Number#/
	local lvalue = runtime.luanumber[ context.self ]
	local rvalue = runtime.luanumber[ context.divisor ]
	if not rvalue or rvalue==Roots['nil'] then
		rvalue = slurpNextValue( context.callState )
		if rvalue == Roots['nil'] then
			error( "Number#/ is mising a divisor" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end
	return runtime.number[ lvalue / rvalue ]
end )

Roots.Number.abs = createLuaFunc( function( context ) -- Number#abs
	local myValue = runtime.luanumber[ context.self ]
	return runtime.number[ math.abs( myValue ) ]
end )

Roots.Number['sin'] = createLuaFunc( function( context ) -- Number#sin
	local myValue = runtime.luanumber[ context.self ]
	return runtime.number[ math.sin(math.rad( myValue )) ]
end )

Roots.Number['cos'] = createLuaFunc( function( context ) -- Number#cos
	local myValue = runtime.luanumber[ context.self ]
	return runtime.number[ math.cos(math.rad( myValue )) ]
end )

Roots.Number.toString = createLuaFunc( function( context ) -- Number#toString
	local theIntrinsicName = rawget( context.self, '__name' )
	if theIntrinsicName then
		return runtime.string[ string.format("%s (0x%04x)", runtime.luastring[theIntrinsicName], runtime.ObjectId[ context.self ] ) ]
	else
		return runtime.string[ tostring( runtime.luanumber[ context.self ] ) ]
	end
end )

Roots.Number.asCode = Roots.Number.toString

