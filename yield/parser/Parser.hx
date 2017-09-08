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
import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.Ref;
import yield.YieldOption;

class Parser
{
	#if macro
	
	private static var workEnv:WorkEnv;
	
	#end
	
	/**
	 * Implement iterators from iterator blocks defined with yield statements.
	 */
	public static macro function run (options:Array<ExprOf<YieldOption>>): Array<Field> {
		
		#if macro
			
			switch (Context.getLocalType()) {
			case null: return null;
			case TInst(_, _): 
				
				workEnv = new WorkEnv();
				
				if (workEnv.alreadyPrecessed())
					return null;
				
				workEnv.markHasProcessed();
				
				checkImports();
				
				initOptions(options);
				
				return parseClass();
				
			default: return null;
			}
			
		#else
			
			return null;
			
		#end
	}
	
	#if macro
	
	private static function checkImports (): Void {
		
		var imports:Array<ImportExpr> = Context.getLocalImports();
		var i:Int = imports.length;
		
		while (--i != -1)
			if (imports[i].mode == ImportMode.IAll)
				Context.fatalError("Imports are not allowed to have `.*` wildcards or `in s` shorthands when using " + WorkEnv.YIELD_KEYWORD + " statement", Context.getLocalClass().get().pos);
	}
	
	private static function initOptions (options:Array<Expr>): Void {
		
		var yieldKeyword:String = null;
		var yieldExplicit:Bool = null;
		
		function throwInvalidOpt (pos:Position)
			Context.fatalError("Invalid option", pos);
			
		function throwDuplicatedOpt (opt:String, pos:Position)
			Context.fatalError(opt + " is already defined", pos);
		
		for (opt in options) {
			
			switch (opt) {
			case (macro YieldOption.Explicit) | (macro yield.YieldOption.Explicit):
				
				if (yieldExplicit == null) yieldExplicit = true;
				else throwDuplicatedOpt("ExplicitTyping", opt.pos);
				
			case (macro YieldOption.Explicit($s)) | (macro yield.YieldOption.Explicit($s)):
				
				var ident:String = ExpressionTools.getConstIdent(s);
				var value:Bool   = if (ident == "false") false else if (ident == "true") true else null; 
				if (value == null) throwInvalidOpt(opt.pos);
				
				if (yieldExplicit == null) yieldExplicit = value;
				else throwDuplicatedOpt("ExplicitTyping", opt.pos);
				
			case (macro YieldOption.Keywork($s)) | (macro yield.YieldOption.Keywork($s)):
				
				var name:String = ExpressionTools.getConstString(s);
				if (name == null) throwInvalidOpt(opt.pos);
				
				if (yieldKeyword == null) yieldKeyword = name;
				else throwDuplicatedOpt("YieldKeyword", opt.pos);
				
			default:
			}
		}
		
		ExpressionTools.defineVarAsDirective(yieldKeyword, "yield");
		ExpressionTools.defineVarAsDirective(yieldExplicit, false);
		
		workEnv.setOptions( yieldKeyword, yieldExplicit );
	}
	
	private static function parseClass (): Array<Field> {
		
		for (field in workEnv.classFields) {
			
			if (field.access.indexOf(Access.AMacro) != -1)
				Context.fatalError("Expression macros cannot be in modules containing Yield implementations", field.pos);
				
			parseField(field);
		}
		
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
			DefaultGenerator.run();
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