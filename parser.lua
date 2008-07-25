require 'lpeg'
require 're'

require 'core'
require 'runtime'
require 'utils'
module('parser',package.seeall)

grammar = [[
	Chunk         <-   &. -> startExpr <Expression> (<Terminator> <Expression>)* -> closeExpr
	Expression    <-   &. -> startExpr <Space> (<Message>/<String>/<Number>/<SubExpression>)+ -> closeExpr
	SubExpression <-   <OpenParen> <Expression> <CloseParen>
	ArgExpression <-   <Chunk> ("," <Space> / &<CloseParen>)
	Message       <-   ( <Identifier> / <Operator> ) -> startMessage <Arguments>?  <Separator>* -> closeMessage
	Arguments     <-   <OpenParen> <ArgExpression>* <CloseParen>
	Identifier    <-   [a-zA-Z_]+
	Operator      <-   [=~`!@$%^&*|<>?/\\+-]+
	Separator     <-   [ .]
	Terminator    <-   ( (%nl / ";") <Space> ) / !.
	
	String        <-   (('"' ([^"]* -> addString) '"') / ("'" ([^']* -> addString) "'")) <Separator>*
	Number        <-   ( ( [+-]? [0-9] [0-9_]* ('.' [0-9] [0-9_]*)? ) / ( [+-]? '.' [0-9] [0-9_]* ) ) -> addNumber <Separator>*

	OpenParen     <-   "(" <Space>
	CloseParen    <-   <Space> ")"
	Space         <-   (%s)*
]]

ast = {}

function pushNode( tagName, str )
	table.insert( ast, { tag=tagName, str=str } )
end

function popNode( expectedTagName )
	local node = table.remove( ast )
	if node.tag ~= expectedTagName then
		error( "Popped a "..node.tag.." off the ast stack when I expected a "..expectedTagName )
	end
	if ast[1] then
		table.insert( ast[#ast], node )
	else
		-- This should only ever get set once, by the first expression
		-- TODO: We could perform a sanity check and error if it was already written.
		ast.rootNode = node
	end
end

function addChild( tagName, str )
	table.insert( ast[#ast], { tag=tagName, str=str } )
end

parseFuncs = {
	startExpr     = function(   ) pushNode( 'expression' ) end,
	closeExpr     = function(   ) popNode(  'expression' ) end,
	startMessage  = function( s ) pushNode( 'message', s ) end,
	closeMessage  = function(   ) popNode(  'message'    ) end,	
	addString     = function( s ) addChild( 'string', s  ) end,
	addNumber     = function( s ) addChild( 'number', s  ) end
}

function parseFile( file )
	return parse( io.input(file):read("*a") )
end

function parse( code )
	local matchLength = re.compile( grammar, parseFuncs ):match( code )
	if not matchLength or (matchLength < #code) then
		table.dump( ast )
		error( "Failed to parse code! (Got to around char "..tostring(matchLength).." / "..(#code)..")" )
	end
	return codeFromAST( ast.rootNode )
end

function codeFromAST( t )
	if t.tag=="expression" then
		local expression = core.createExpression()
		for i,childAST in ipairs(t) do
			core.addChildren( expression, codeFromAST( childAST ) )
		end
		return expression
		
	elseif t.tag=="message" then
		local message = core.createMessage( t.str )
		for i,childAST in ipairs(t) do
			core.addChildren( message.arguments, codeFromAST( childAST ) )
		end
		return message

	elseif t.tag=="string" then
		return runtime.string[t.str]
		
	elseif t.tag=="number" then
		return runtime.number[tonumber(t.str)]
		
	else
		error( "AST with unknown tag encountered: "..tostring(t.tag) )
	end
end

core.Roots.String.interpolate = core.createLuaFunc( function( context )
	local str = runtime.luastring[ context.self ]
	str = string.gsub( str, "#(%b{})", function( chunkWithBrackets )
		local chunk = parse( string.sub( chunkWithBrackets, 2, -2 ) )
		local value = core.eval( context.callState.callingContext, context.callState.callingContext, chunk )
		return runtime.luastring[ value ]
	end)
	return runtime.string[ str ]
end )

function runString( code )
	local Lawn = core.Roots.Lawn
	Lawn.program = parser.parse( code )
	if arg.debugLevel >= 3 then
		print( "Parsed program tree:" )
		core.printObjectAsXML( Lawn.program )
	end
	core.eval( Lawn, Lawn, Lawn.program )
	-- TODO: error codes
end