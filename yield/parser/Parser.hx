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
package yield.parser;
import haxe.macro.Expr;
#if macro
import haxe.macro.Context;
import haxe.macro.ComplexTypeTools;
import yield.parser.WorkEnv;
import yield.parser.WorkEnv.RetType;
import yield.parser.YieldSplitter;
import yield.parser.YieldSplitter.IteratorBlockData;
import yield.generators.DefaultGenerator;
import yield.parser.tools.ExpressionTools;
import yield.parser.tools.MetaTools;
import yield.parser.tools.MetaTools.MetaToolsOption;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.Ref;
import haxe.macro.TypeTools;
#end
import yield.YieldOption;

class Parser
{
	/**
	 * Implement iterators from iterator blocks defined with yield statements.
	 * Preferably use `:yield` metadata instead of `:build` or `:autoBuild` metadata
	 * except when dealing with abstracts.
	 */
	public static macro function run (options:Array<ExprOf<YieldOption>>): Array<Field> {
		
		#if macro
			
			var t:Type = Context.getLocalType();
			
			switch (t) {
			case null: return null;
			case TInst(_.get() => ct, _): 
				
				if (alreadyProcessed(ct))
					return null;
				
				var hasAutoBuild:Bool = false;
				
				for (md in ct.meta.get())
					if (md.name == ":yield" && md.params != null)
						for (p in md.params) options.push(p);
					else if (isBuildMeta(":autoBuild", md))
						hasAutoBuild = true;
				
				var env = createEnv(ct, t, options, hasAutoBuild);
				
				return parseClass(env);
				
			default: return null;
			}
			
		#else
			
			return null;
			
		#end
	}
	
	#if macro
	
	private static function auto (): Void {
		haxe.macro.Compiler.addGlobalMetadata("", "@:build(yield.parser.Parser.autoRun())", true, true, false);
	}
	
	private static macro function autoRun (): Array<Field> {
		
		var t:Type = Context.getLocalType();
		
		switch (t) {
			case null: return null;
			case TInst(_.get() => ct, _): 
				
				if (alreadyProcessed(ct))
					return null;
				
				var hasYieldMeta:Bool = false;
				var hasAutoBuild:Bool = false;
				
				var options:Array<Expr> = null;
				
				for (md in ct.meta.get())
					if (md.name == ":yield") {
						hasYieldMeta = true;
						options = md.params != null ? md.params : [];
					}
					else if (isBuildMeta(":build", md))
						return null;
					else if (isBuildMeta(":autoBuild", md))
						hasAutoBuild = true;
				
				if (!hasYieldMeta)
					return null;
				
				var env = createEnv(ct, t, options, hasAutoBuild);
				
				return parseClass(env);
				
			default: return null;
		}
	}
	
	public static macro function extendedRun (options:Array<ExprOf<YieldOption>>): Array<Field> {
		
		var t:Type = Context.getLocalType();
		
		switch (t) {
		case null: return null;
		case TInst(_.get() => ct, _):
			
			if (alreadyProcessed(ct))
				return null;
			
			var hasAutoBuild:Bool = false;
			
			for (md in ct.meta.get())
				if (md.name == ":yield" || isBuildMeta(":build", md)) 
					return null;
			
			var env = createEnv(ct, t, options, false);
			
			return parseClass(env);
			
		default: return null;
		}
	}
	
	private static function isBuildMeta (buildName:String, md:MetadataEntry): Bool {
		
		return if (md.name == buildName && md.params != null && md.params.length == 1)
			switch (md.params[0].expr) {
			case ExprDef.ECall(_e, _):
				switch (_e) {
				case (macro yield.parser.Parser.run): true;
				default: false;
				}
			default: false;
			}
		else false;
	}
	
	private static function alreadyProcessed (classType:ClassType): Bool {
		return classType.meta.has(":yield_processed");
	}
	
	private static function markHasProcessed (classType:ClassType): Void {
		classType.meta.add(":yield_processed", [], classType.pos);
	}
	
	private static function createEnv (ct:ClassType, t:Type, options:Array<Expr>, hasAutoBuild:Bool): WorkEnv {
		
		markHasProcessed(ct);
		var env = new WorkEnv(ct, t);
		initOptions(options, !hasAutoBuild, env);

		return env;
	}
	
	private static function initOptions (options:Array<Expr>, canExtend:Bool, env:WorkEnv): Void {
		
		var yieldKeyword:String = null;
		var yieldExplicit:Bool = null;
		var yieldExtend:Bool = null;
		
		function throwInvalidOpt (pos:Position)
			Context.fatalError("Invalid option", pos);
		
		function throwDuplicatedOpt (opt:String, pos:Position)
			Context.fatalError(opt + " is already defined", pos);
		
		function throwConflict (opt:String, pos:Position)
			Context.fatalError(opt + " and :autoBuild(" + ExprTools.toString(macro yield.parser.Parser.run()) + ") metadata are conflicted", pos);
		
		var i:Int = options.length;
		var opt:Expr;
		while (--i != -1) {
			opt = options[i];
			
			switch (opt) {
			case (macro Extend) | (macro YieldOption.Extend) | (macro yield.YieldOption.Extend):
				if (!canExtend) throwConflict(YieldOption.Extend(true).getName(), opt.pos);
				else if (yieldExtend == null) yieldExtend = true;
				else throwDuplicatedOpt(YieldOption.Extend(true).getName(), opt.pos);
				options.splice(i,1);
			case (macro Extend($s)) | (macro YieldOption.Extend($s)) | (macro yield.YieldOption.Extend($s)):
				var ident:String = ExpressionTools.getConstIdent(s);
				var value:Bool   = if (ident == "false") false else if (ident == "true") true else null; 
				if (value == null) throwInvalidOpt(opt.pos);
				
				if (!canExtend) throwConflict(YieldOption.Extend(true).getName(), opt.pos);
				else if (yieldExtend == null) yieldExtend = value;
				else throwDuplicatedOpt(YieldOption.Extend(true).getName(), opt.pos);
				options.splice(i,1);
				
			case (macro Explicit) | (macro YieldOption.Explicit) | (macro yield.YieldOption.Explicit):
				if (yieldExplicit == null) yieldExplicit = true;
				else throwDuplicatedOpt(YieldOption.Explicit(true).getName(), opt.pos);
			case (macro Explicit($s)) | (macro YieldOption.Explicit($s)) | (macro yield.YieldOption.Explicit($s)):
				var ident:String = ExpressionTools.getConstIdent(s);
				var value:Bool   = if (ident == "false") false else if (ident == "true") true else null; 
				if (value == null) throwInvalidOpt(opt.pos);
				
				if (yieldExplicit == null) yieldExplicit = value;
				else throwDuplicatedOpt(YieldOption.Explicit(true).getName(), opt.pos);
				
			case (macro Keyword($s)) | (macro YieldOption.Keyword($s)) | (macro yield.YieldOption.Keyword($s)):
				var name:String = ExpressionTools.getConstString(s);
				if (name == null) throwInvalidOpt(opt.pos);
				
				if (yieldKeyword == null) yieldKeyword = name;
				else throwDuplicatedOpt(YieldOption.Keyword("").getName(), opt.pos);
				
			default:
				throwInvalidOpt(opt.pos);
			}
		}
		
		ExpressionTools.defineVarAsDirective(yieldKeyword, "yield");
		ExpressionTools.defineVarAsDirective(yieldExplicit, false);
		ExpressionTools.defineVarAsDirective(yieldExtend, false);
		
		if (yieldExtend) {
			env.localClass.meta.add(":autoBuild", [macro yield.parser.Parser.extendedRun($a{options})] , env.localClass.pos);
		}
		
		WorkEnv.setOptions( yieldKeyword, yieldExplicit, yieldExtend );
	}
	
	private static function parseClass (env:WorkEnv): Array<Field> {

		for (field in env.classFields)
			parseField(field, env);
		
		return env.classFields;
	}
	
	private static function parseField (field:Field, env:WorkEnv): Void {
		
		var func:Function;
		var alternativeRetType:ComplexType;
		
		switch (field.kind) {
			
			case FFun(_f):
				
				func               = _f;
				alternativeRetType = null;
				
			case FProp(_, _, _t, _e) | FVar(_t, _e):
				
				MetaTools.option = MetaToolsOption.None;
				
				if (MetaTools.hasMeta(WorkEnv.YIELD_KEYWORD, _e)) {
					
					func               = MetaTools.selectedFunc;
					alternativeRetType = switch (_t) {
						case ComplexType.TFunction(__args, __ret): 	__ret;
						default: null;
					};
					
				} else {
					return;
				}
		}
		
		if (func.ret == null) {
			func.ret = alternativeRetType;
		}
		
		env.setFieldData(field, func);
		
		var success:Bool = parseFunction(field.name, func, field.pos, env);
		
		if (success) {
			DefaultGenerator.run(env);
		}
	}
	
	/**
	 * @return `true` is returned if the function defines iterator blocks and was successfully parsed.
	 */
	@:noCompletion
	public static function parseFunction (name:String, f:Function, pos:Position, env:WorkEnv): Bool {
		
		MetaTools.option = MetaToolsOption.None;
		
		if (!MetaTools.hasMeta(WorkEnv.YIELD_KEYWORD, f, true)) {
			return false;
		}
		
		if (name == null) {
			Context.fatalError( "Yielded functions must have a name to be parsed", pos );
		}
		
		var returnType:ComplexType;
		var funcRetType:RetType;
		
		// Typing
		
		if (f == MetaTools.selectedFunc) {
			
			env.yieldMode = true;
			
			if (f.ret == null) {
				
				if (WorkEnv.YIELD_EXPLICIT) {
					Context.fatalError( "Method must have a return type when using " + WorkEnv.YIELD_KEYWORD + " expressions", pos );
				} else {
					f.ret		= macro:StdTypes.Dynamic;
					returnType	= macro:StdTypes.Dynamic;
					funcRetType	= RetType.DYNAMIC;
				}
				
			} else {
				
				switch (f.ret) {
					
					case (macro:Iterator<$p>)
					   | (macro:StdTypes.Iterator<$p>):
						
						returnType  = p;
						funcRetType = RetType.ITERATOR;
						
					case (macro:Iterable<$p>)
					   | (macro:StdTypes.Iterable<$p>):
						
						returnType  = p;
						funcRetType = RetType.ITERABLE;
						
					case (macro:Dynamic)
					   | (macro:StdTypes.Dynamic):
					   
						returnType  = macro:StdTypes.Dynamic;
						funcRetType = RetType.DYNAMIC;
						
					default:
						
						var resolvedType:Null<Type> = try {
							ComplexTypeTools.toType(f.ret);
						} catch (err:Dynamic) {
							null;
						};
						
						if (resolvedType != null) {
							
							var retType:Type = TypeTools.followWithAbstracts(resolvedType);
							
							var iteratorType:Type = ComplexTypeTools.toType(macro:Iterator<Dynamic>);
							var iterableType:Type = ComplexTypeTools.toType(macro:Iterable<Dynamic>);
							
							switch (retType) {
								
								case Type.TAnonymous(_.get() => { fields : [_, { name:"next", type:TFun([],iteratortype), isPublic:true, expr:_, kind:_, meta:_, overloads:_, params:_, doc:_, pos:_ }], status:status }) if (Context.unify(retType, iteratorType)):
									
									returnType = TypeTools.toComplexType(iteratortype);
									funcRetType = RetType.ITERATOR;
									
								case Type.TAnonymous(_.get() => { fields : [{ name:"iterator", type:TFun([],iterabletype), isPublic:true, expr:_, kind: _, meta:_, overloads:_, params:_, doc:_, pos:_ }], status:status }) if (Context.unify(retType, iterableType)):
									
									returnType = TypeTools.toComplexType(iterabletype);
									funcRetType = RetType.ITERABLE;
									
								case TDynamic(_):
									
									returnType  = f.ret;
									funcRetType = RetType.DYNAMIC;
									
								case _:
									
									Context.fatalError(ComplexTypeTools.toString(f.ret) + " should be Iterator or Iterable", pos);
									
							}
							
						} else {
							
							returnType  = macro:Dynamic;
							funcRetType = RetType.DYNAMIC;
							
							Context.fatalError(ComplexTypeTools.toString(f.ret) + "'s complexity is not supported due to the type parameter. Please use directly Iterator or Iterable to use " + WorkEnv.YIELD_KEYWORD, pos);
							
						}
				}
				
			}
			
		} else {
			
			env.yieldMode = false;
			
			returnType  = macro:StdTypes.Dynamic;
			funcRetType = RetType.DYNAMIC;
		}
		
		// Parse
		
		env.setFunctionData(name, f, funcRetType, returnType, pos);
		
		var yieldSplitter:YieldSplitter = new YieldSplitter( env );
		var ibd:IteratorBlockData = yieldSplitter.split(f, pos);
		
		// Generate type
		
		if (env.yieldMode || env.requiredBySubEnv)
			f.expr = DefaultGenerator.add(ibd, pos, env);
		
		return true;
	}
	
	#end
}

private typedef Options = {
	yieldKeyword:String, 
	yieldExplicit:Bool, 
	yieldExtend:Bool
}