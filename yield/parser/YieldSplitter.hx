/*
 * The MIT License
 * 
 * Copyright (C)2017 Dimitri Pomier
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#if (macro || display)
package yield.parser;
import yield.parser.tools.ExpressionTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import yield.parser.PositionManager.LinkedPosition;
import yield.parser.eactions.ActionParser;
import yield.parser.eparsers.*;
import yield.parser.idents.IdentChannel;
import yield.parser.env.WorkEnv;

typedef IteratorBlock = Array<Expr>;

typedef IteratorBlockData = Array<IteratorBlock>;

class YieldSplitter {
	
	public var eblockParser    (default, null):EBlockParser;
	public var ewhileParser    (default, null):EWhileParser;
	public var eforParser      (default, null):EForParser;
	public var eifParser       (default, null):EIfParser;
	public var eswitchParser   (default, null):ESwitchParser;
	public var eternaryParser  (default, null):ETernaryParser;
	public var econstParser    (default, null):EConstParser;
	public var emetaParser     (default, null):EMetaParser;
	public var efunctionParser (default, null):EFunctionParser;
	public var evarsParser     (default, null):EVarsParser;
	public var etryParser      (default, null):ETryParser;
	
	public var actionParser    (default, null):ActionParser;
	
	public var cursor         (default, null):UInt;
	public var iteratorBlocks (default, null):IteratorBlockData = [];
	public var yieldedScope:Bool;
	
	private var m_env:WorkEnv;
	private var m_positionManager:PositionManager;
	private var m_yieldMetaCounter:Int = 0;
	
	//{ INIT
	
	public function new (env:WorkEnv) {
		m_env = env;
		yieldedScope = true;
		actionParser    = new ActionParser(this, env);
		eblockParser    = new EBlockParser(this, env);
		ewhileParser    = new EWhileParser(this, env);
		eforParser      = new EForParser(this, env);
		eifParser       = new EIfParser(this, env);
		eswitchParser   = new ESwitchParser(this, env);
		eternaryParser  = new ETernaryParser(this, env);
		econstParser    = new EConstParser(this, env);
		emetaParser     = new EMetaParser(this, env);
		efunctionParser = new EFunctionParser(this, env);
		evarsParser     = new EVarsParser(this, env);
		etryParser      = new ETryParser(this, env);
	}
	
	public function split (f:Function, pos:Position): IteratorBlockData {
		
		if (f.expr == null) Context.fatalError("Function body required", pos);
		
		cursor = 0;
		iteratorBlocks  = new IteratorBlockData();
		iteratorBlocks[cursor] = new IteratorBlock();
		m_positionManager = new PositionManager(iteratorBlocks);
		
		m_env.openScope();
		
		switch (f.expr.expr) {
			case EBlock(_exprs):
				for (lexpr in _exprs) parse(lexpr, false);
			case EUntyped(_e):
				var wasUntyped:Bool = m_env.untypedMode;
				m_env.untypedMode = true;
				parse(_e, false);
				m_env.untypedMode = wasUntyped;
			case _:
				parse(f.expr, false);
		}
		
		m_env.closeScope();
		
		var yieldBreak:Expr = { expr: null, pos: f.expr.pos };
		registerBreakAction(yieldBreak);
		
		#if (yield_debug_no_display || !display && !yield_debug_display)
		addIntoBlock(yieldBreak);
		#else
		ExpressionTools.checkIsInEBlock(f.expr).push(yieldBreak);
		#end
		
		YieldSplitterOptimizer.optimizeAll(this, m_positionManager, m_env, f.expr.pos);
		
		return iteratorBlocks;
	}
	
	//}
	
	//{ ITERATOR OPERATIONS
	
	public function moveCursor (): Void {
		#if (yield_debug_no_display || !display && !yield_debug_display)
		if (iteratorBlocks[++cursor] == null)
			iteratorBlocks[cursor] = new IteratorBlock();
		#end
	}
	
	public function addIntoBlock (e:Expr, ?pos:Int): Void {
		#if (yield_debug_no_display || !display && !yield_debug_display)
		if (m_env.untypedMode) {
			e = { expr: EUntyped(e), pos: e.pos };
		}
		iteratorBlocks[pos == null ? cursor : pos].push(e);
		#end
	}
	
	public function spliceIteratorBlocks (pos:Int, len:Int): Void {
		#if (yield_debug_no_display || !display && !yield_debug_display)
		if (pos < 0) {
			len += pos;
			pos = 0;
		}
		
		iteratorBlocks.splice(pos, len);
		m_positionManager.adjustIteratorPos(len *-1, pos);
		cursor -= len;
		#end
	}
	
	#if (yield_debug_no_display || !display && !yield_debug_display)
	public function registerGotoAction (emptyExpr:Expr, toPos:Int): Void {
		
		var lp:LinkedPosition = { e: emptyExpr, pos: toPos };
		m_env.gotoActions.push(lp);
		m_positionManager.addPosPointer(lp);
	}
	
	public function registerSetAction (emptyExpr:Expr, toPos:Int): Void {
		
		var lp:LinkedPosition = { e: emptyExpr, pos: toPos };
		m_env.setActions.push(lp);
		m_positionManager.addPosPointer(lp);
	}
	#end
	
	public function registerBreakAction (emptyExpr:Expr): Void {
		
		#if (!yield_debug_no_display && (display || yield_debug_display))
		addDisplayDummy(emptyExpr);
		#else
		var lp:LinkedPosition = { e: emptyExpr, pos: null };
		m_env.breakActions.push(lp);
		#end
	}
	
	public function addDisplayDummy (emptyDummy:Expr): Void {
		
		if (m_env.yieldedType != null) {
			processDisplayDummy(emptyDummy);
		}
	}
	
	private function processDisplayDummy (emptyDummy:Expr): Void {
		
		var ft = m_env.functionReturnType;
		emptyDummy.expr = EReturn(macro (null:$ft));
	}
	
	//}
	
	//{ PARSING
	
	/**
	 * Parse `e` in a temporary iterator block such as an expression which are not sub-parsed.
	 * @return Quantity of yield statements.
	 */
	public function parseOut (e:Expr, returnValue:Bool, returnedType:String = "value", ?ic:IdentChannel): Int {
		
		var initialPos:UInt = cursor;
		
		moveCursor();
		
		var yieldCount:Int = parse(e, false, ic);
		
		spliceIteratorBlocks(initialPos + 1, cursor - initialPos);
		
		if (returnValue && yieldCount != 0) {
			#if (yield_debug_no_display || !display && !yield_debug_display)
			Context.fatalError("Missing return " + returnedType, e.pos);
			#end
		}
		
		return yieldCount;
	}
	
	/**
	 * @return Quantity of yield statements.
	 */
	public function parse (e:Expr, subParsing:Bool, ?ic:IdentChannel, inlined = false): Int {
		
		#if (!yield_debug_no_display && (display || yield_debug_display))
		subParsing = true;
		#end
		
		var yieldCount:Int = m_yieldMetaCounter;
		
		switch (e.expr) {
			
			case EBlock(_exprs): 
				eblockParser.run(e, subParsing, _exprs);
				
			case EMeta(_s, _e):
				if (_s.name == m_env.yieldKeywork && (_s.params == null || _s.params.length == 0))
					m_yieldMetaCounter += 1;
				emetaParser.run(e, subParsing, _s, _e);
				
			case EReturn(_e):
				if (yieldedScope && m_env.yieldMode)
					Context.fatalError( "Cannot return a value from an iterator. Use the " + m_env.yieldKeywork + " return expression to return a value, or " + m_env.yieldKeywork + " break to end the iteration", e.pos );
				else if (_e != null)
					parse(_e, true, ic);
				
			case EVars(_vars): 
				evarsParser.run(e, subParsing, _vars, ic);
				
			case EFunction(_name, _f): 
				efunctionParser.run(e, subParsing, _name, _f, inlined);
				
			case ECall(_e, _params):
				for (i in 0..._params.length) parse(_params[i], true, ic);
				parse(_e, true);
				if (!subParsing) addIntoBlock(e);
				
			case EField(_e, _field):
				parse(_e, true);
				if (!subParsing) addIntoBlock(e);
				
			case ENew(_t, _params):
				parseTypePath(_t, true);
				for (k in 0..._params.length) parse(_params[k], true);
				if (!subParsing) addIntoBlock(e);
				
			case EObjectDecl(_fields):
				for (lfield in _fields) parse(lfield.expr, true);
				if (!subParsing) addIntoBlock(e);
				
			case EParenthesis(_e):
				parse(_e, true);
				if (!subParsing) addIntoBlock(e);
				
			case EBinop(_op, _e1, _e2):
				switch (_e1.expr) {
				case EConst(__c):
					var beingModified:Bool = switch (_op) { case OpAssign, OpAssignOp(_): true; case _: false; }
					switch (_op) {
					case Binop.OpAssign: econstParser.run(_e1, true, __c, ic, true, beingModified);
					case _:              econstParser.run(_e1, true, __c, ic, false, beingModified);
					}
				default:
					parse(_e1, true, ic);
				}
				parse(_e2, true, ic);
				if (!subParsing) addIntoBlock(e);
				
			#if (haxe_ver < 4.000)
			case EIn(_e1, _e2):
				
				parse(_e1, true, ic);
				parse(_e2, true, ic);
				if (!subParsing) addIntoBlock(e);
			#end
				
			case EIf(_econd, _eif, _eelse): 
				eifParser.run(e, subParsing, _econd, _eif, _eelse);
				
			case ETernary(_econd, _eif, _eelse): 
				eternaryParser.run(e, subParsing, _econd, _eif, _eelse);
				
			case EUnop(_op, _postFix, _e):
				var beingModified:Bool = switch (_op) { case OpIncrement, OpDecrement: true; case _: false; }
				switch (_e.expr) {
					case EConst(_c): econstParser.run(_e, true, _c, ic, false, beingModified);
					case _:           parse(_e, true);
				}
				if (!subParsing) addIntoBlock(e);
				
			case ECast(_e, _t):
				parse(_e, true);
				if (_t != null) parseComplexType(_t, true);
				if (!subParsing) addIntoBlock(e);
				
			case EWhile(_econd, _e, _normalWhile): 
				ewhileParser.run(e, subParsing, _econd, _e, _normalWhile);
				
			case EFor(_it, _expr): 
				eforParser.run(e, subParsing, _it, _expr);
				
			case EArrayDecl(_values):
				for (lexpr in _values) parse(lexpr, true);
				if (!subParsing) addIntoBlock(e);
				
			case EArray(_e1, _e2):
				parse(_e1, true);
				parse(_e2, true);
				if (!subParsing) addIntoBlock(e);
				
			case ETry(_e, _catches): 
				etryParser.run(e, subParsing, _e, _catches);
				
			case EThrow(_e):
				parse(_e, true, ic);
				if (!subParsing) addIntoBlock(e);
				m_env.addLocalThrow();
				
			case EConst(_c): 
				econstParser.run(e, subParsing, _c, IdentChannel.Normal);
				
			case EContinue:
				ewhileParser.addContinue(e);
				if (!subParsing) addIntoBlock(e);
				
			case EBreak:
				ewhileParser.addBreak(e);
				if (!subParsing) addIntoBlock(e);
				
			case EUntyped(_e):
			
				var wasUntyped = m_env.untypedMode;
				
				m_env.untypedMode = true;
				parse(_e, true, ic);
				m_env.untypedMode = wasUntyped;

				if (!subParsing) addIntoBlock(e);
				
			case ECheckType(_e, _t):
				parse(_e, true, ic);
				parseComplexType(_t, true);
				if (!subParsing) addIntoBlock(e);
				
			case ESwitch(_e, _cases, _edef): 
				eswitchParser.run(e, subParsing, _e, _cases, _edef);
				
			case EDisplay(_e, _isCall):
			case EDisplayNew(_t):
		}
		
		return m_yieldMetaCounter - yieldCount;
	}
	
	public function parseMetadata (m:Metadata, subParsing:Bool): Void {
		for (lmetadataEntry in m) parseMetadataEntry(lmetadataEntry, subParsing);
	}
	
	public function parseMetadataEntry (s:MetadataEntry, subParsing:Bool): Void {
		if (s.params != null) 
			for (lexpr in s.params)
				parse(lexpr, subParsing);
	}
	
	public function parseTypePath (tp:TypePath, subParsing:Bool): Void {
		if (tp.params != null)
			for (ltypeParam in tp.params)
				parseTypeParam(ltypeParam, subParsing);
	}
	
	public function parseTypeParam (tparam:TypeParam, subParsing:Bool): Void {
		switch (tparam) {
			case TPType(_t):
				parseComplexType(_t, subParsing);
			case TPExpr(_e):
				parse(_e, subParsing);
		}
	}
	
	public function parseComplexType (t:ComplexType, subParsing:Bool): Void {
		switch (t) {
		case TPath(_p):
			parseTypePath(_p, subParsing);
			
		case TFunction(_args, _ret):
			for (larg in _args)
				parseComplexType(larg, subParsing);
			parseComplexType(_ret, subParsing);
			
		case TAnonymous(_fields):
			for (lfield in _fields)
				parseField(lfield, subParsing);
			
		case TParent(_t):
			parseComplexType(_t, subParsing);
			
		case TExtend(_p, _fields):
			for (ltp in _p)
				parseTypePath(ltp, subParsing);
			for (lfield in _fields)
				parseField(lfield, subParsing);
			
		case TOptional(_t):
			parseComplexType(_t, subParsing);
			
		#if (haxe_ver >= 4.000)
		case TNamed(_n, _t):
			parseComplexType(_t, subParsing);
			
		case TIntersection(_tl):
			for (lct in _tl)
				parseComplexType(lct, subParsing);
		#end
		}
	}
	
	public function parseField (field:Field, subParsing:Bool): Void {
		if (field.meta != null) parseMetadata(field.meta, subParsing);
		parseFieldType(field.name, field.kind, field.pos, subParsing);
	}
	
	public function parseFieldType (name:String, t:FieldType, pos:Position, subParsing:Bool): Void {
		switch (t) {
		case FVar(_t, _e):
			if (_t != null) parseComplexType(_t, subParsing);
			if (_e != null) parse(_e, subParsing);
			
		case FFun(_f):
			efunctionParser.parseFun(_f, pos, subParsing);
			
		case FProp(_get, _set, _t, _e):
			if (_t != null) parseComplexType(_t, subParsing);
			if (_e != null) parse(_e, subParsing);
		}
	}
	
	public function parseTypeParamDecl (t:TypeParamDecl, subParsing:Bool): Void {
		if (t.meta != null) parseMetadata(t.meta, subParsing);
		if (t.constraints != null)
			for (lconstraint in t.constraints)
				parseComplexType(lconstraint, subParsing);
		if (t.params != null)
			for (lparam in t.params)
				parseTypeParamDecl(lparam, subParsing);
	}
	
	public function parseFunctionArg (a:FunctionArg, subParsing:Bool): Void {
		if (a.type != null) parseComplexType(a.type, subParsing);
		if (a.value != null) parse(a.value, subParsing);
		if (a.meta != null) parseMetadata(a.meta, subParsing);
	}
	
	public function parseVar (v:Var, subParsing:Bool, ic:IdentChannel): Void {
		if (v.type != null) parseComplexType(v.type, subParsing);
		if (v.expr != null) parse(v.expr, subParsing, ic);
	}
	
	//}
	
}
#end