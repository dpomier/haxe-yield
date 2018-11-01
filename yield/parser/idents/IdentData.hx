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
package yield.parser.idents;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Position;
import yield.parser.env.WorkEnv;
import yield.parser.env.WorkEnv.Scope;

typedef IdentData = {
	
	/**
	 * If identType is `Accession` it is ensure that names.length is equal to 1
	 */
	var names:Array<String>;
	
	/**
	 * If identType is `Accession` it is ensure that initialized.length is equal to 1
	 */
	var initialized:Array<Bool>;
	
	/**
	 * If identType is `Accession` it is ensure that types.length is equal to 1
	 */
	var types:Array<ComplexType>;
	
	var ident:IdentRef;
	
	var channel:IdentChannel;
	
	var options:Array<IdentOption>;
	
	var scope:Scope;
	
	var env:WorkEnv;
	
	var pos:Position;
}
#end