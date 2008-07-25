-- runtime.blank()/runtime.childFrom() use runtime.string, and
-- runtime.string needs core.String to be defined to work properly,
-- so DON'T SUPPLY A NAME HERE.
Object = runtime.blank( )
String = runtime.childFrom( Object )

-- Convert String objects to/from Lua flavor
runtime.string    = {}
runtime.luastring = {}
setmetatable( runtime.string, {
	__index = function( self, string )
		local stringObject = runtime.childFrom( String )
		self[ string ] = stringObject
		runtime.luastring[ stringObject ] = string
		return stringObject
	end
} )

runtime.Meta.__tostring = function( object )
  -- return runtime.luastring[ object ] or "--nil--"
  if runtime.luastring[object] then
    return "'"..runtime.luastring[object].."'"
  elseif object == String then
    return runtime.luastring[object.__name]
  else
  	return runtime.luastring[ eval( Roots.Lawn, object, messageCache['toString'] ) ] or '???'
  end
end

Object.__name = runtime.string["Object"]
String.__name = runtime.string["String"]
Roots = runtime.childFrom( Object, "Roots" )
Roots.Object = Object
Roots.String = String
Roots.Roots  = Roots

Roots.Array      = runtime.childFrom( Roots.Object,     "Array"      )
Roots.Expression = runtime.childFrom( Roots.Array,      "Expression" ) 
Roots.Function   = runtime.childFrom( Roots.Expression, "Function"   )
Roots.CallState  = runtime.childFrom( Roots.Object,     "CallState"  )
                                                                 
Roots.Context    = runtime.childFrom( Roots.Object,     "Context"   )
Roots.Lawn       = runtime.childFrom( Roots.Context,    "Lawn"      )

--TODO: Should this really inherit from object, or not?
Roots['nil'] = runtime.childFrom( Roots.Object, "nil (the object)" )
Roots['nil']['or'] = createLuaFunc( 'rValue', function( context ) 
	return context.rValue
end )

runtime.Meta.nilValue = Roots['nil']

