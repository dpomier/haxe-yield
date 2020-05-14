/*
 * The MIT License
 * 
 * Copyright (C)2020 Dimitri Pomier
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
package yield.generators;
import haxe.crypto.Md5;
import haxe.macro.Expr.Function;
import haxe.macro.Expr.FunctionArg;
import haxe.macro.Expr.Position;
import yield.parser.env.WorkEnv;
import yield.parser.env.WorkEnv.Scope;
import yield.parser.idents.IdentChannel;

class NameController {
	
	private static var ID_CHANNELS:Map<IdentChannel, String> = [
		IdentChannel.Normal 	 => "y",
		IdentChannel.IterationOp => "i"
	];
	
	private static var anonymousCounters:Map<String, UInt> = new Map<String, UInt>();
	
	/**
	 * Name of the extra-type generated when using yield statements.
	 */
	public static function extraTypeName (env:WorkEnv, number:UInt): String {
		return env.functionsPack.join("_") + "_" + env.fieldName + "__I" + number;
	}
	
	/**
	 * Unique name of the anonymous function.
	 */
	public static function anonymousFunction (env:WorkEnv, f:Function, pos:Position): String {
		var id:String = Md5.encode(env.functionsPack.join("."));
		if (!anonymousCounters.exists(id))
			anonymousCounters.set(id, 0);
		else
			anonymousCounters[id] += 1;
		return "anon" + anonymousCounters.get(id) + id;
	}
	
	/**
	 * Field name of the class's instance.
	 */
	public static function fieldInstance (): String {
		return "_instance_";
	}
	
	/**
	 * Constructor arg name of the class's instance.
	 */
	public static function argInstance (): String {
		return "instance";
	}
	
	/**
	 * Field name of a required WorkEnv parent.
	 */
	public static function fieldParent (env:WorkEnv, dependence:WorkEnv): String {
		return "_d" + env.parentDependencies.indexOf(dependence) + "_";
	}
	
	/**
	 * Constructor arg name of a required WorkEnv parent.
	 */
	public static function argParent (env:WorkEnv, dependence:WorkEnv): String {
		return "_d" + env.parentDependencies.indexOf(dependence) + "_p";
	}
	
	/**
	 * Constructor arg name of a required parent's local.
	 */
	public static function argParentAsVar (name:String): String {
		return name + "_pav";
	}
	
	/**
	 * Constructor arg name of any user argument.
	 */
	public static function argArgument (argument:FunctionArg): String {
		return argument.name + "_a";
	}
	
	/**
	 * Name of any user local vars and functions.
	 */
	public static function localVar (originalName:String, scope:Scope, ic:IdentChannel, number:UInt): String {
		return originalName + "_" + scope.id + ID_CHANNELS[ic] + number;
	}
	
	/**
	 * Name of any user local vars and functions from a parent environment.
	 */
	public static function parentVar (originalName:String, scope:Scope, ic:IdentChannel, envId:Int): String {
		return originalName + "_" + ID_CHANNELS[ic] + envId + "pav";
	}
	
	/**
	 * Name of any iterative functions.
	 */
	public static function iterativeFunction (iteratorPos:UInt): String {
		return "_" + iteratorPos + "_";
	}
	
	/**
	 * Name of the iteration's cursor field.
	 */
	public static function fieldCursor ():String return "_cursor_";
	
	/**
	 * Name of the iteration's current field.
	 */
	public static function fieldCurrent ():String return "_current_";
	
	/**
	 * Name of the iteration's isConsumed field.
	 */
	public static function fieldIsConsumed ():String return "_isConsumed_";
	
	/**
	 * Name of the iteration's isCompleted field.
	 */
	public static function fieldCompleted ():String return "_isComplete_";
	
}
#end