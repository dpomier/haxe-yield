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
#if macro
package yield.parser.tools;
import haxe.macro.Context;
import haxe.macro.Expr;

enum MetaToolsOption {
	None;
	SkipNestedFunctions;
}

class MetaTools
{
	
	private static var functionStack:Array<Function> = [];
	private static var onlyInBody:Bool = false;
	
	public static var selectedFunc (default, null):Function;
	public static var selectedExpr (default, null):Expr;
	public static var selectedPos  (default, null):Position;
	
	public static var option:MetaToolsOption;
	
	public static function hasMeta (name:String, ?f:Function, ?e:Expr, onlyInBody:Bool = false): Bool {
		
		MetaTools.onlyInBody = onlyInBody;
		
		selectedExpr = null;
		selectedFunc = null;
		selectedPos  = null;
		
		if (f == null && e == null) return false;
		
		var runExpr:Bool = f == null;
		
		functionStack = [f];
		
		while (functionStack.length != 0) {
			
			selectedFunc = functionStack.pop();
			
			if (runExpr) {
				
				runExpr = false;
				hasMetaExpr(name, e);
				
			} else if (hasMetaFun(name, selectedFunc)) {
				return true;
			}
		}
		return false;
	}
	
	public static function hasMetaExpr (name:String, e:Expr, ?onlyFunctionBody:Bool): Bool {
		
		if (e == null || e.expr == null) return false;
		
		selectedExpr = e;
		selectedPos  = e.pos;
		
		if (onlyFunctionBody != null) {
			MetaTools.onlyInBody = onlyFunctionBody;
		}
		
		switch (e.expr) {
			case EConst(_c):
			case EArray(_e1, _e2):
				return hasMetaExpr(name, _e1) || hasMetaExpr(name, _e2); 
				
			case EBinop(_op, _e1, _e2):
				return hasMetaExpr(name, _e1) || hasMetaExpr(name, _e2); 
				
			case EField(_e, _field):
				return hasMetaExpr(name, _e);
				
			case EParenthesis(_e):
				return hasMetaExpr(name, _e);
				
			case EObjectDecl(_fields):
				for (lfield in _fields)
					if (hasMetaExpr(name, lfield.expr)) return true;
				
			case EArrayDecl(_values):
				for (lvalue in _values)
					if (hasMetaExpr(name, lvalue)) return true; 
				
			case ECall(_e, _params):
				if (hasMetaExpr(name, _e)) return true;
				for (lparam in _params)
					if (hasMetaExpr(name, lparam)) return true; 
				
			case ENew(_t, _params):
				if (hasMetaTP(name, _t))
					return true;
				for (lparam in _params)
					if (hasMetaExpr(name, lparam)) return true;
				
			case EUnop(_op, _postFix, _e):
				return hasMetaExpr(name, _e);
				
			case EVars(_vars):
				for (lvar in _vars)
					if (hasMetaV(name, lvar)) return true;
				
			case EFunction(_name, _f):
				if (option != MetaToolsOption.SkipNestedFunctions)
					functionStack.push(_f);
					
			case EBlock(_exprs):
				for (lexpr in _exprs)
					if (hasMetaExpr(name, lexpr)) return true;
				
			case EFor(_it, _expr):
				if (hasMetaExpr(name, _it)) {
					throwUnexpectedMeta(name);
					return true;
				}
				return hasMetaExpr(name, _expr);
				
			case EIn(_e1, _e2):
				return hasMetaExpr(name, _e1) || hasMetaExpr(name, _e2);
				
			case EIf(_econd, _eif, _eesle):
				return hasMetaExpr(name, _econd) || hasMetaExpr(name, _eif) || _eesle != null && hasMetaExpr(name, _eesle);
				
			case EWhile(_econd, _e, _normalWhile):
				return hasMetaExpr(name, _econd) || hasMetaExpr(name, _e);
				
			case ESwitch(_e, _cases, _edef):
				if (hasMetaExpr(name, _e)) return true;
				for (lcase in _cases)
					if (hasMetaC(name, lcase)) return true;
				return _edef != null && hasMetaExpr(name, _edef);
				
			case ETry(_e, _catches):
				if (hasMetaExpr(name, _e)) return true;
				for (lcatch in _catches)
					if (hasMetaCatch(name, lcatch)) return true;
				
			case EReturn(_e):
				return _e != null && hasMetaExpr(name, _e);
				
			case EBreak:
			case EContinue:
				
			case EUntyped(_e):
				return hasMetaExpr(name, _e);
				
			case EThrow(_e):
				return hasMetaExpr(name, _e);
				
			case ECast(_e, _t):
				return hasMetaExpr(name, _e) || _t != null && hasMetaCT(name, _t);
				
			case EDisplay(_e, _isCall):
				return hasMetaExpr(name, _e);
				
			case EDisplayNew(_t):
				return hasMetaTP(name, _t);
				
			case ETernary(_econd, _eif, _eelse):
				return hasMetaExpr(name, _econd) || hasMetaExpr(name, _eif) || hasMetaExpr(name, _eelse);
				
			case ECheckType(_e, _t):
				return hasMetaExpr(name, _e) || hasMetaCT(name, _t);
				
			case EMeta(_s, _e):
				return hasMetaME(name, _s) || hasMetaExpr(name, _e);
		}
		
		return false;
	}
	
	private static function hasMetaM (name:String, m:Metadata): Bool {
		
		for (lmetadataEntry in m) {
			
			if (hasMetaME(name, lmetadataEntry)) return true;
		}
		
		return false;
	}
	
	private static function hasMetaME (name:String, s:MetadataEntry): Bool {
		
		selectedPos = s.pos;
		
		if (s.name == name) return true;
		
		if (s.params != null) {
			
			for (lexpr in s.params) {
				if (hasMetaExpr(name, lexpr)) return true;
			}
		}
		
		return false;
	}
	
	private static function hasMetaTP (name:String, tp:TypePath): Bool {
		
		if (tp.params == null) return false;
		
		for (ltypeParam in tp.params) {
			if (hasMetaTParam(name, ltypeParam))
				return true;
		}
		
		return false;
	}
	
	private static function hasMetaTParam (name:String, tparam:TypeParam): Bool {
		
		switch (tparam) {
			
			case TPType(_t):
				return hasMetaCT(name, _t);
				
			case TPExpr(_e):
				return hasMetaExpr(name, _e);
		}
		
		return false;
	}
	
	private static function hasMetaCT (name:String, t:ComplexType): Bool {
		
		switch (t) {
						
			case TPath(_p):
				
				if (hasMetaTP(name, _p)) {
					return true;
				}
				
			case TFunction(_args, _ret):
				
				for (larg in _args) {
					if (hasMetaCT(name, larg)) {
						return true;
					}
				}
				
				return hasMetaCT(name, _ret);
				
			case TAnonymous(_fields):
				
				for (lfield in _fields) {
					
					if (hasMetaF(name, lfield)) {
						return true;
					}
				}
				
			case TParent(_t):
				
				return hasMetaCT(name, _t);
				
			case TExtend(_p, _fields):
				
				for (ltp in _p) {
					if (hasMetaTP(name, ltp)) {
						return true;
					}
				}
				
				for (lfield in _fields) {
					if (hasMetaF(name, lfield)) {
						throwUnexpectedMeta(name);
						return true;
					}
				}
				
			case TOptional(_t):
				
				return hasMetaCT(name, _t);
		}
		
		return false;
	}
	
	private static function hasMetaF (name:String, field:Field): Bool {
		
		return field.meta != null && hasMetaM(name, field.meta) || hasMetaFT(name, field.kind);
	}
	
	private static function hasMetaFT (name:String, t:FieldType): Bool {
		
		switch (t) {
			case FVar(_t, _e):
				
				if (_t != null && hasMetaCT(name, _t)) {
					return true;
				}
				
				if (_e != null && hasMetaExpr(name, _e)) {
					return true;
				}
				
			case FFun(_f):
				
				return hasMetaFun(name, _f);
				
			case FProp(_get, _set, _t, _e):
				
				if (_t != null && hasMetaCT(name, _t)) return true;
				
				if (_e != null && hasMetaExpr(name, _e)) return true;
		}
		
		return false;
	}
	
	private static function hasMetaFun (name:String, f:Function): Bool {
		
		for (larg in f.args) {
			if (hasMetaFA(name, larg)) {
				return true;
			}
		}
		
		if (f.ret != null && hasMetaCT(name, f.ret)) {
			
			throwUnexpectedMeta(name);
			return true;
		}
		
		if (f.expr != null) {
			
			var useMeta:Bool = hasMetaExpr(name, selectedFunc.expr);
			
			if (useMeta) return true;
		}
		
		if (f.params != null) {
			
			for (lparam in f.params) {
				if (hasMetaTPD(name, lparam)) {
					
					throwUnexpectedMeta(name);
					return true;
				}
			}
		}
		
		return false;
	}
	
	private static function hasMetaTPD (name:String, t:TypeParamDecl): Bool {
		
		if (t.meta != null) {
			
			if (hasMetaM(name, t.meta)) {
				throwUnexpectedMeta(name);
				return true;
			}
		}
		
		if (t.constraints != null) {
			
			for (lconstraint in t.constraints) {
				if (hasMetaCT(name, lconstraint)) return true;
			}
		}
		
		if (t.params != null) {
			
			for (lparam in t.params) {
				if (hasMetaTPD(name, lparam)) return true;
			}
		}
		
		return false;
	}
	
	private static function hasMetaFA (name:String, a:FunctionArg): Bool {
		
		if (a.type != null && hasMetaCT(name, a.type)) return true;
		
		if (a.value != null && hasMetaExpr(name, a.value)) return true;
		
		if (a.meta != null && hasMetaM(name, a.meta)) {
			throwUnexpectedMeta(name);
			return true;
		}
		
		return false;
	}
	
	private static function hasMetaV (name:String, v:Var): Bool {
		
		if (v.type != null && hasMetaCT(name, v.type)) return true;
		
		return v.expr != null && hasMetaExpr(name, v.expr);
	}
	
	private static function hasMetaC (name:String, c:Case): Bool {
		
		for (lvalue in c.values) {
			if (hasMetaExpr(name, lvalue)) {
				throwUnexpectedMeta(name);
				return true;
			}
		}
		
		if (c.guard != null && hasMetaExpr(name, c.guard)) return true;
		
		return c.expr != null && hasMetaExpr(name, c.expr);
	}
	
	private static function hasMetaCatch (name:String, c:Catch): Bool {
		
		return hasMetaCT(name, c.type) || hasMetaExpr(name, c.expr);
	}
	
	private static function throwUnexpectedMeta (name:String): Void {
		if (onlyInBody) Context.fatalError("Unexpected " + name, selectedPos);
	}
	
}
#end