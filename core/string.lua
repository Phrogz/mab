Roots.String['+'] = createLuaFunc( 'stringToAppend', function( context ) -- String#+
	return runtime.string[ runtime.luastring[context.self] .. runtime.luastring[ context.stringToAppend ] ]
end )

Roots.String['*'] = createLuaFunc( 'reps', function( context ) -- String#*
	local string = runtime.luastring[ context.self ]
	local reps   = runtime.luanumber[ context.reps ]

	if not reps then
		reps = slurpNextValue( context.callState )
		if reps == Roots['nil'] then
			error( "String#* is mising a repetition count" )
		end
		rvalue = runtime.luanumber[ rvalue ]
	end

	return runtime.string[ string.rep( string, reps ) ]
end )

Roots.String.asCode = createLuaFunc( function( context ) -- String#asCode
	return runtime.string[ string.format( "%q", runtime.luastring[context.self] ) ]
end )