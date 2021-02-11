/*
 * The MIT License
 * 
 * Copyright (C)2021 Dimitri Pomier
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
package yield.parser.checks;
import yield.parser.tools.ExpressionTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ComplexType;
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
import haxe.macro.Type;
import yield.parser.env.WorkEnv;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentData;
import yield.parser.tools.IdentCategory;

class TypeInferencer {

	public static function resolveReturnType (?returnType:Null<Type>, ?returnComplexType:Null<ComplexType>, pos:Position):ReturnKind {
		
		if (returnType == null) {
			returnType = try {
				ComplexTypeTools.toType(returnComplexType);
			} catch (err:Dynamic) {
				null;
			};
		} else {
			returnComplexType = TypeTools.toComplexType(returnType);
		}
		
		if (returnType != null) {
			
			var retType:Type = TypeTools.followWithAbstracts(returnType);
			
			switch (retType) {
					
				case TDynamic(_):
					
					return RBoth(macro:StdTypes.Dynamic);
				
				case Type.TAnonymous(_.get() => at):
					
					var isIterator = false;
					var isIterable = false;
					var iteratorYieldedType:Null<ComplexType>;
					var iterableYieldedType:Null<ComplexType>;

					var hasNext = false,
						nextRet:ComplexType;
					var hasHasNext = false;
					var hasIterator = false,
						iteratorRet:ComplexType;

					// TODO: workaround for https://github.com/HaxeFoundation/haxe/issues/7657
					for (field in at.fields) if (field.name == "hasNext" && field.params.length == 0) {
						
						switch field.type {
							case TFun([], TAbstract(_.get() => { name: "Bool", pack: [] },[])):
								hasHasNext = true;
							case _:
						}

					} else if (field.name == "next" && field.params.length == 0) {
						
						switch field.type {
							case TFun([], ret):
								hasNext = true;
								nextRet = TypeTools.toComplexType(ret);
							case _:
						}

					} else if (field.name == "iterator" && field.params.length == 0) {
						
						switch field.type {
							case TFun([], ret):
								hasIterator = true;
								iteratorRet = TypeTools.toComplexType(ret);
							case _:
						}
					}

					if (hasHasNext && hasNext) {
						isIterator = true;
						iteratorYieldedType = nextRet;
					}

					if (hasIterator) {						
						switch resolveReturnType(iteratorRet, pos) {
							case RIterator(p):
								isIterable = true;
								iterableYieldedType = p;
							case _:
						}
					}

					return if (isIterator && isIterable) {
						RBoth(getLowerComplexType(iteratorYieldedType, iterableYieldedType));
					} else if (isIterator) {
						RIterator(iteratorYieldedType);
					} else if (isIterable) {
						RIterable(iterableYieldedType);
					} else {
						Context.fatalError(ComplexTypeTools.toString(returnComplexType) + " should be Iterator or Iterable", pos);
					};
					
				case retType:

					return Context.fatalError(ComplexTypeTools.toString(returnComplexType) + " should be Iterator or Iterable", pos);
					
			}
			
		} else {
			
			return RBoth(macro:StdTypes.Dynamic);
			
		}
	}

	public static function getBaseType (types:Array<Null<Type>>, pos):Type {

		var result:Null<Type>;

		var typeCount:Int = types.length;

		inline function unifyable (t:Null<Type>):Bool {
			return switch t {
				case null | TMono(_): false;
				case _: true;
			}
		}

		if (typeCount == 0) {
			return ComplexTypeTools.toType(macro:StdTypes.Void);
		} else if (typeCount == 1) {
			result = types[0];
		} else {
			
			for (i in 0...typeCount) {
				if (unifyable(types[i])) {
					switch types[i] {
						case TMono(_): continue;
						case _:
					}
					var unify = true;
					for (j in 0...typeCount) {
						if (i != j && types[j] != null && unifyable(types[i]) && !Context.unify(types[i], types[i])) {
							unify = false;
							break;
						}
					}
					if (unify) {
						result = types[i];
						break;
					}
				}
			}
		}
		
		return result == null ? ComplexTypeTools.toType(macro:Dynamic) : result;
	}

	public static function getLowerType (t1:Type, t2:Type):Type {

		return if (Context.unify(t1, t2)) {
			t1;
		} else if (Context.unify(t2, t1)) {
			t2;
		} else {
			ComplexTypeTools.toType(macro:StdTypes.Dynamic);
		}
	}

	public static inline function getLowerComplexType (t1:ComplexType, t2:ComplexType):ComplexType {

		return TypeTools.toComplexType(getLowerType(ComplexTypeTools.toType(t1), ComplexTypeTools.toType(t2)));
	}

	public static function resolveComplexType (expr:Null<Expr>, env:WorkEnv):Null<ComplexType> {
		return switch TypeInferencer.tryInferExpr(expr, env, IdentChannel.Normal) {
			case null: TypeTools.toComplexType(Context.typeof(expr));
			case t: t;
		}
	}
	
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
									
									if (ic == null) ic = IdentChannel.Normal;
									
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
							t = tryInferExpr(larg.value, env, ic);
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
					
					var lt:Null<ComplexType> = tryInferExpr(_field.expr, env, ic);
					
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

			case ECall(e, params):
				
				var t:Null<ComplexType> = tryInferExpr(e, env, ic);

				if (t != null) {
					return switch (t) {
						case TFunction(args, ret): ret;
						case _: null;
					}
				} else {
					return null;
				}
			
			case ECheckType(e, t):
				return t;
			
			case ENew(p, _):
				return TPath(p);
				
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