/*
 * The MIT License
 * 
 * Copyright (C)2023 Dimitri Pomier
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
import haxe.macro.Expr;
import haxe.macro.Expr.FunctionArg;
import haxe.macro.Expr.TypeDefinition;
import haxe.macro.Expr.TypePath;
import yield.parser.YieldSplitter.IteratorBlockData;

class BuildingData {
	
	public var typeDefinition   (default, null):TypeDefinition;
	public var typePath			(default, null):TypePath;
	public var constructorArgs  (default, null):Array<FunctionArg>;
	public var constructorBlock (default, null):Array<Expr>;
	public var givenArguments   (default, null):Array<Expr>;
	public var lastSequence		(default, null):Int;
	public var instanceFunctionBody:Expr;
	
	public function new (td:TypeDefinition, tpack:TypePath, ibd:IteratorBlockData) {
		
		typeDefinition   = td;
		typePath		 = tpack;
		constructorArgs  = [];
		constructorBlock = [];
		givenArguments   = [];
		lastSequence	 = ibd.length - 1;
		instanceFunctionBody = null;
		
		typeDefinition.pack = typePath.pack;
	}
	
}
#end