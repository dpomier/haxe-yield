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
package yield.parser.tools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
using haxe.macro.ExprTools;

enum MetaToolsOption {
	None;
	SkipNestedFunctions;
}

class MetaTools {
	
	private static var functionStack:Array<Function> = [];
	private static var onlyInBody:Bool = false;
	private static var resolveType:Bool = false;
	
	public static var selectedFunc (default, set):Null<Function>;
	public static var selectedExpr (default, set):Null<Expr>;
	public static var selectedPos  (default, set):Null<Position>;
	public static var resolvedType (default, null):Null<Type>;
	public static var metaFound    (default, null):Bool = false;

	private static function set_selectedFunc (v:Function):Function {
		return selectedFunc = (!resolveType || resolvedType == null) ? v : selectedFunc;
	}
	private static function set_selectedExpr (v:Expr):Expr {
		return selectedExpr = (!resolveType || resolvedType == null) ? v : selectedExpr;
	}
	private static function set_selectedPos (v:Position):Position {
		return selectedPos = (!resolveType || resolvedType == null) ? v : selectedPos;
	}
	
	public static var option:MetaToolsOption;
	
	public static function hasMeta (name:String, ?f:Function, ?e:Expr, onlyInBody = false, resolveType = false): Bool {
		
		MetaTools.onlyInBody = onlyInBody;
		MetaTools.resolveType = resolveType;
		
		selectedExpr = null;
		selectedFunc = null;
		selectedPos  = null;
		resolvedType = null;
		metaFound    = false;
		
		if (f == null && e == null) return false;
		
		var runExpr:Bool = f == null;
		
		functionStack = [f];
		
		while (functionStack.length != 0 && !metaFound) {
			
			selectedFunc = functionStack.pop();
			
			if (runExpr) {
				
				runExpr = false;
				hasMetaExpr(name, e);
				
			} else if (hasMetaFun(name, selectedFunc) || metaFound) {
				if (selectedFunc == null) throw "should nevre be null here";
				return true;
			}
		}
		if (metaFound && selectedFunc == null) throw "should nevre be null here";
		return metaFound;
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
				
			case EBinop(_, _e1, _e2) #if (haxe_ver < 4.000), EIn(_e1, _e2) #end:
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
			case EDisplayNew(_t):
				
			case ETernary(_econd, _eif, _eelse):
				return hasMetaExpr(name, _econd) || hasMetaExpr(name, _eif) || hasMetaExpr(name, _eelse);
				
			case ECheckType(_e, _t):
				return hasMetaExpr(name, _e) || hasMetaCT(name, _t);
				
			case EMeta(_s, _e):

				if (resolveType) {
					return hasMetaME(name, _s) && typeResolution(_e) || hasMetaExpr(name, _e);
				} else {
					return metaFound || hasMetaME(name, _s) || hasMetaExpr(name, _e);
				}

				
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
		
		if (s.name == name) {
			metaFound = true;
			return true;
		}
		
		if (s.params != null) {
			
			for (lexpr in s.params) {
				if (hasMetaExpr(name, lexpr)) {
					metaFound = true;
					return true;
				}
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
				
			#if (haxe_ver >= 4.000)
			case TNamed(_n, _t):
				
				return hasMetaCT(name, _t);
				
			case TIntersection(_tl):
				
				for (lct in _tl) {
					if (hasMetaCT(name, lct)) {
						return true;
					}
				}
			#end
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

	private static function typeResolution (e:Null<Expr>):Bool {

		if (!resolveType || resolvedType != null) {
			return true;
		}

		if (e != null) {
			
			e = switch (e.expr) {
				// case EConst(c):
				// case EArray(e1, e2):
				// case EBinop(op, e1, e2):
				// case EField(e, field):
				// case EParenthesis(e):
				// case EObjectDecl(fields):
				// case EArrayDecl(values):
				// case ECall(e, params):
				// case ENew(t, params):
				// case EUnop(op, postFix, e):
				case EVars(vars): null;
				// case EFunction(name, f):
				// case EBlock(exprs):
				case EFor(it, expr): null;
				// case EIf(econd, eif, eelse):
				case EWhile(econd, e, normalWhile): null;
				// case ESwitch(e, cases, edef):
				// case ETry(e, catches):
				case EReturn(_e): _e;
				case EBreak: null;
				case EContinue: null;
				case EUntyped(e): null;
				case EThrow(e): null;
				// case ECast(e, t):
				case EDisplay(e, displayKind): null;
				case EDisplayNew(t): null;
				// case ETernary(econd, eif, eelse):
				// case ECheckType(e, t):
				case EMeta(s, _e): _e;
				case _: e;
			};

			if (e == null) return false;

			try {
				resolvedType = Context.typeof(e);
			} catch (_:Dynamic) {
				resolvedType = null;
			}
			
			if (resolvedType != null) {
				resolvedType = switch (resolvedType) {
					case TDynamic(null): null;
					case _: resolvedType;
				};
			}
			
		}
		
		return resolvedType != null;
	}
	
	private static function throwUnexpectedMeta (name:String): Void {
		if (onlyInBody) Context.fatalError("Unexpected " + name, selectedPos);
	}

	public static function resolveMetaType (expr:Expr):Type {

		return extractFromMeta(expr, "yield", function (s:MetadataEntry, e:Expr) {

			return switch (e.expr) {
				case EReturn(_e) if (_e != null): 

					try {
						Context.typeof(_e);
					} catch (_:Dynamic) {
						null;
					};

				case _: null;
			}

		});
	}

	static function extractFromMeta<T> (expr:Expr, meta:String, f:MetadataEntry->Expr->Null<T>):Null<T> {

		var selection:Null<T> = null;

		function browse (e:Expr) {
			switch(e.expr) {
				case EMeta(s, e) if (s.name == "yield"):
					selection = f(s, e);
					if (selection == null) {
						e.iter(browse);
					}
				case _:
					e.iter(browse);
			}
		}

		browse(expr);

		return selection;

	}
	
}
#end