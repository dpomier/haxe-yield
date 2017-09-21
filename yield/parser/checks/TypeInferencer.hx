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
package yield.parser.checks;
import yield.parser.tools.ExpressionTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ComplexType;
import yield.parser.WorkEnv;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentData;
import yield.parser.tools.IdentCategory;

class TypeInferencer
{
	
	/**
	 * @return Returns the complex type of `expr` if it can be determined.
	 */
	public static function tryInferExpr (expr:Null<Expr>, ?env:WorkEnv, ?ic:IdentChannel): Null<ComplexType> {
		
		if (expr == null) return null;
		
		expr = ExpressionTools.getExpr(expr);
		
		switch (expr.expr) {
			case EConst(_c):
				
				switch (_c) {
					case CInt(_):
						return macro:StdTypes.Int;
					case CFloat(_):
						return macro:StdTypes.Float;
					case CString(_):
						return macro:String;
					case CIdent(__s):
						
						switch (__s) {
							
							case "true" | "false":
								return macro:StdTypes.Bool;
								
							default:
								
								if (env == null) {
									return null;
								} else {
									
									if (ic == null) throw "ident channel needs to be specified when env does";
									
									var identCat:IdentCategory = env.getIdentCategoryOf(__s, ic);
									
									switch (identCat) {
										case IdentCategory.LocalVar(_definition):
											return _definition.types[_definition.names.indexOf(__s)];
											
										case IdentCategory.InstanceField(_type)
										   | IdentCategory.InstanceStaticField(_type, _)
										   | IdentCategory.ImportedField(_type): 
											return _type;
											
										case IdentCategory.Unknown: 
											return null;
									}
								}
						}
						
					case CRegexp(_):
						return macro:EReg;
				}
				
			case EFunction(_name, _f):
				
				if (_f.ret != null) {
					
					var argTypes:Array<ComplexType> = [];
					var allTyped:Bool = true;
					for (larg in _f.args) {
						
						var t:ComplexType;
						
						if (larg.type == null) {
							t = tryInferExpr(larg.value, env);
							if (t == null) {
								allTyped = false;
								break;
							}
						} else {
							t = larg.type;
						}
						
						if (larg.opt != null && larg.opt || larg.value != null) {
							argTypes.push(ComplexType.TOptional(t));
						} else {
							argTypes.push(t);
						}
						
					}
					
					if (allTyped) {
						return ComplexType.TFunction(argTypes, _f.ret);
					} else {
						return null;
					}
					
				} else {
					return null;
				}
				
			case EObjectDecl(_fields):
				
				var lfields:Array<Field> = [];
				
				for (_field in _fields) {
					
					var lt:Null<ComplexType> = tryInferExpr(_field.expr, env);
					
					if (lt == null) {
						return null;
					}
					
					var fieldType:FieldType = FVar(lt);
					
					lfields.push({
						name: _field.field,
						doc : null,
						access: [APublic],
						kind  : fieldType,
						pos   : _field.expr.pos,
						meta  : null
					});
				}
				
				return ComplexType.TAnonymous(lfields);
				
			default:
				return null;
		}
	}
	
	public static function tryInferField (kind:FieldType): Null<ComplexType> {
		
		switch (kind) {
			case FieldType.FVar(_t, _e):
				if (_t != null) return _t;
				else return tryInferExpr(_e, null);
				
			case FieldType.FFun(_f):
				return tryInferFunction(_f);
				
			case FieldType.FProp(_, _, _t, _e):
				if (_t != null) return _t;
				else return tryInferExpr(_e, null);
		}
		return null;
	}
	
	public static function tryInferFunction (f:Function): Null<ComplexType> {
		
		if (f.ret != null) {
			
			var argTypes:Array<ComplexType> = [];
			
			for (arg in f.args) {
				var inferred:Null<ComplexType> = tryInferArg(arg);
				if (inferred != null) argTypes.push(inferred != null ? inferred : macro:StdTypes.Dynamic);
			}
			
			return ComplexType.TFunction(argTypes, f.ret);
			
		} else {
			return null;
		}
	}
	
	public static function tryInferArg (arg:FunctionArg): Null<ComplexType> {
		
		if (arg.type != null) return arg.type;
		else return tryInferExpr(arg.value, null);
	}
	
	public static function checkArgumentType (a:FunctionArg, pos:Position): Void {
		if (a.type == null) {
			a.type = TypeInferencer.tryInferExpr(a.value, null);
			if (a.type == null) throwTypeRequiredFor(a.name, pos);
		}
	}
	
	public static function checkLocalVariableType (v:Var, env:WorkEnv, ic:IdentChannel, pos:Position): Void {
		if (v.type == null) {
			v.type = TypeInferencer.tryInferExpr(v.expr, env, ic);
			if (v.type == null) throwTypeRequiredFor(v.name, pos);
		}
	}
	
	private static function throwTypeRequiredFor (name:String, pos:Position): Void {
		Context.fatalError("Type required on static targets for local variable " + name, pos);
	}
	
}
#end