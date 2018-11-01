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
package yield.macrotime;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class Tools {
	
	public static macro function getIterator (e:Expr): Expr {
		
		var t:Type = Context.typeExpr(e).t;
		
		if (Context.unify(t, Context.resolveType(macro:StdTypes.Iterable<Dynamic>, Context.currentPos()))) {
			e.expr = ECall({ expr: EField({ expr: e.expr, pos: e.pos }, "iterator"), pos: e.pos }, []);
			return e;
		}
		
		if (Context.unify(t, Context.resolveType(macro:StdTypes.Iterator<Dynamic>, Context.currentPos()))) {
			return e;
		}
		
		return e;
	}
}