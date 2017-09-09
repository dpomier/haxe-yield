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
#end
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.Ref;
import yield.YieldOption;

class Parser
{
	/**
	 * Implement iterators from iterator blocks defined with yield statements.
	 */
	public static macro function run (options:Array<ExprOf<YieldOption>>): Array<Field> {
		
		#if macro
			
			var t:Type = Context.getLocalType();
			
			switch (t) {
			case null: return null;
			case TInst(_.get() => ct, _): 
				
				if (alreadyProcessed(ct))
					return null;
				
				return parseClass(ct, t, options);
				
			default: return null;
			}
			
		#else
			
			return null;
			
		#end
	}
	
	#if macro
	
	private static var workEnv:WorkEnv;
	
	private static var runBuild (default, never):String = ExprTools.toString(macro yield.parser.Parser.run);
	
	private static function autoRun (): Array<Field> {
		
		var t:Type = Context.getLocalType();
		
		switch (t) {
			case null: return null;
			case TInst(_.get() => ct, _): 
				
				if (alreadyProcessed(ct))
					return null;
				
				var yieldMeta:MetadataEntry = null;
				var hasBuildRun:Bool = false;
				
				function hasBuildYield (ct:ClassType): Bool {
					for (md in ct.meta.get())
						if (md.name == ":build" && md.params != null && md.params.length == 1)
							switch (md.params[0].expr) {
							case ExprDef.ECall(_e1, _):
								if (ExprTools.toString(_e1) == runBuild)
									return true;
							default:
							}
					return false;
				}
				
				for (md in ct.meta.get())
					if (md.name == ":build" 
					&& md.params != null 
					&& md.params.length == 1)
						switch (md.params[0].expr) {
						case ExprDef.ECall(_e1, _):
							if (ExprTools.toString(_e1) == runBuild)
								hasBuildRun = true;
						default:
						}
					else if (md.name == ":yield")
						yieldMeta = md;
				
				if (yieldMeta == null)
					return null;
				else if (!hasBuildRun) 
					return parseClass(ct, t, yieldMeta.params);
				else
					return Context.fatalError("Meta @:yield and @:build(yield.parser.Parser.run()) can't be defined on the same class", ct.pos);
				
				
				
			default: return null;
		}
	}
	
	private static function auto (): Void {
		haxe.macro.Compiler.addGlobalMetadata("", "@:build(yield.parser.Parser.autoRun())", true, true, false);
	} 
	
	private static function alreadyProcessed (classType:ClassType): Bool {
		return classType.meta.has(":yield_processed");
	}
	
	private static function markHasProcessed (classType:ClassType): Void {
		classType.meta.add(":yield_processed", [], classType.pos);
	}
	
	private static function initOptions (options:Array<Expr>): Void {
		
		var yieldKeyword:String = null;
		var yieldExplicit:Bool = null;
		var yieldExtend:Bool = null;
		
		function throwInvalidOpt (pos:Position)
			Context.fatalError("Invalid option", pos);
			
		function throwDuplicatedOpt (opt:String, pos:Position)
			Context.fatalError(opt + " is already defined", pos);
		
		for (opt in options) {
			
			switch (opt) {
			case (macro YieldOption.Extend) | (macro yield.YieldOption.Extend):
				if (yieldExtend == null) yieldExtend = true;
				else throwDuplicatedOpt("Extend", opt.pos);
			case (macro YieldOption.Extend($s)) | (macro yield.YieldOption.Extend($s)):
				var ident:String = ExpressionTools.getConstIdent(s);
				var value:Bool   = if (ident == "false") false else if (ident == "true") true else null; 
				if (value == null) throwInvalidOpt(opt.pos);
				
				if (yieldExtend == null) yieldExtend = value;
				else throwDuplicatedOpt("Extend", opt.pos);
				
			case (macro YieldOption.Explicit) | (macro yield.YieldOption.Explicit):
				if (yieldExplicit == null) yieldExplicit = true;
				else throwDuplicatedOpt("ExplicitTyping", opt.pos);
			case (macro YieldOption.Explicit($s)) | (macro yield.YieldOption.Explicit($s)):
				var ident:String = ExpressionTools.getConstIdent(s);
				var value:Bool   = if (ident == "false") false else if (ident == "true") true else null; 
				if (value == null) throwInvalidOpt(opt.pos);
				
				if (yieldExplicit == null) yieldExplicit = value;
				else throwDuplicatedOpt("ExplicitTyping", opt.pos);
				
			case (macro YieldOption.Keyword($s)) | (macro yield.YieldOption.Keyword($s)):
				var name:String = ExpressionTools.getConstString(s);
				if (name == null) throwInvalidOpt(opt.pos);
				
				if (yieldKeyword == null) yieldKeyword = name;
				else throwDuplicatedOpt("YieldKeyword", opt.pos);
				
			default:
				throwInvalidOpt(opt.pos);
			}
		}
		
		ExpressionTools.defineVarAsDirective(yieldKeyword, "yield");
		ExpressionTools.defineVarAsDirective(yieldExplicit, false);
		ExpressionTools.defineVarAsDirective(yieldExtend, false);
		
		if (yieldExtend) {
			workEnv.classType.meta.add(":autoBuild", [macro yield.parser.Parser.run($a{options})] , workEnv.classType.pos);
		}
		
		workEnv.setOptions( yieldKeyword, yieldExplicit, yieldExtend );
	}
	
	private static function parseClass (ct:ClassType, t:Type, options:Array<ExprOf<YieldOption>>): Array<Field> {
		
		markHasProcessed(ct);
		
		workEnv = new WorkEnv(ct, t);
		
		initOptions(options);
		
		for (field in workEnv.classFields)
			parseField(field);
		
		return workEnv.classFields;
	}
	
	private static function parseField (field:Field): Void {
		
		var func:Function;
		var alternativeRetType:ComplexType;
		
		switch (field.kind) {
			
			case FFun(_f):
				
				func				= _f;
				alternativeRetType 	= null;
				
			case FProp(_, _, _t, _e) | FVar(_t, _e):
				
				MetaTools.option = MetaToolsOption.None;
				
				if (MetaTools.hasMeta(WorkEnv.YIELD_KEYWORD, _e)) {
					
					func 				= MetaTools.selectedFunc;
					alternativeRetType 	= switch (_t) {
						case ComplexType.TFunction(__args, __ret): 	__ret;
						default: 									null;
					};
					
				} else {
					return;
				}
		}
		
		if (func.ret == null) {
			func.ret = alternativeRetType;
		}
		
		workEnv.setFieldData(field, func);
		
		var success:Bool = parseFunction(field.name, func, field.pos, workEnv);
		
		if (success) {
			DefaultGenerator.run(workEnv);
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
						Context.fatalError( ComplexTypeTools.toString(f.ret) + " should be Iterator or Iterable", pos );
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