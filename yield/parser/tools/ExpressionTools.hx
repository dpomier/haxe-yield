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
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;

class ExpressionTools
{
	
	public static function checkIsInEBlock (e:Expr): Array<Expr> {
		
		switch (e.expr) {
			
			case EBlock(_exprs): 
				
				return _exprs;
				
			default: 
				
				var exprs:Array<Expr> = [{expr:e.expr, pos:e.pos}];
				
				e.expr = EBlock(exprs);
				
				return exprs;
		}
	}
	
	public static function getConstIdent (e:Expr): String {
		
		return switch (e.expr) {
			case EConst(_c):
				switch (_c) {
					case CIdent(__s): __s;
					case _: null;
				}
			default: null;
		};
	}
	
	public static function getConstString (e:Expr): String {
		
		return switch (ExpressionTools.getExpr(e).expr) {
			case EConst(_c):
				switch (_c) {
					case CString(__s): __s;
					default: null;
				}
			default: null;
		}
	}
	
	public static function getExpr (e:Expr): Expr {
		return switch (e.expr) {
			case EParenthesis(_e):
				getExpr(_e);
			default:
				e;
		}
	}
	
	public static function makeCall (fnName:String, args:Array<Expr>, pos:Position): Expr {
		
		return {
			expr : ExprDef.ECall(
				{ expr: EField({ expr: EConst(CIdent("this")), pos: pos }, fnName), pos: pos },
				args
			),
			pos : pos
		};
	}
	
	/**
	 * Define the variable `ident` as a compiler directive. If the value of `arg` is not equals to `defaultValue`, the directive is ignored. Otherwise, if the directive is specified the value is overrode.
	 */
	public static macro function defineVarAsDirective (ident:Expr, defaultValue:Expr): Expr {
		
		var argName:String = ExprTools.toString(ident);
		var assign:Expr;
		
		switch (defaultValue.expr) {
			
			case EConst(c):
				
				switch (c) {
					case CString(_):
						assign = macro $ident = v;
					case CInt(_):
						assign = macro $ident = Std.parseInt(v);
					case CFloat(_):
						assign = macro $ident = Std.parseFloat(v);
					case CIdent(_):
						assign = macro if (v == "true" || v == "1") $ident = true; else if (v == "false" || v == "0") $ident = false; else if (v == "null") $ident = null; else $ident = $defaultValue;
					default:
						assign = macro $ident = $defaultValue;
				}
				
			default:
				Context.fatalError("The value must be a constant", defaultValue.pos);
		}
		
		var a = macro if ($ident == null) {
			
			$ident = $defaultValue;
			
			if (Context.defined($v{argName})) {
				
				var v = Context.definedValue($v{argName});
				if (v != null) {
					v = StringTools.trim(v);
					$assign;
				}
			}
		};
		
		trace(a);
		trace(ExprTools.toString(a));
		return a;
	}
	
	/**
	 * @param t Type of the type parameter. It must be a `TInst` with a `KTypeParameter` kind.
	 * @param name Name of the type parameter, if relevant.
	 * @return
	 */
	public static function convertToTypeParamDecl (t:Type, ?name:String): TypeParamDecl {
		
		var constraints:Array<ComplexType> = [];
		var params:Array<TypeParamDecl> = [];
		
		switch (t) {
			case Type.TInst(_.get() => _t, _params):
				
				// name
				if (name == null) {
					name = _t.name;
				}
				
				// constraints
				switch (_t.kind) {
					case KTypeParameter(_constraints):
						for (c in _constraints) constraints.push(TypeTools.toComplexType(c));
					default:
				}
				
				// params
				for (__t in _params) {
					params.push( convertToTypeParamDecl(__t) );
				}
				
			default: return null;
		};
		
		return {
			constraints: constraints,
			meta: null,
			name: name,
			params: params
		};
	}
	
}
#end