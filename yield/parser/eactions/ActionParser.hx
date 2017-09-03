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
package yield.parser.eactions;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.macro.Context;
import haxe.macro.Expr;
import yield.parser.eparsers.BaseParser;

class ActionParser extends BaseParser
{
	
	public static function addActionToExpr (action:Action, e:Expr): Void {
		
		var ls:Serializer = new Serializer();
		ls.serialize(action);
		
		var lexpr = e.expr;
		
		e.expr = EMeta({
			name: WorkEnv.YIELD_KEYWORD, 
			params: [{ expr:EConst(CString( ls.toString() )), pos:e.pos }], 
			pos:e.pos
		},{
			expr: lexpr, 
			pos: e.pos
		});
	}
	
	public static function getAction (e:Expr): Null<Action> {
		
		switch (e.expr) {
			case EConst(__c):
				
				switch (__c) {
					case CString(___s):
						
						var u = new Unserializer(___s);
						var o:Dynamic = null;
						
						try {
							o = u.unserialize();
						} catch (err:Dynamic) {
							return null;
						}
						
						if (Std.is(o, Action)) {
							return o;
						}
						
						
					default:
				}
			default:
		}
		return null;
	}
	
	public function executeAction (action:Action, e:Expr): Void {
		
		switch (action) {
			case DefineChannel(ic):
				
				switch (e.expr) {
					case EConst(_c):
						m_ys.econstParser.run(e, true, _c, ic);
					default:
						Context.fatalError("Action " + action.getName() + " only works for constants", e.pos);
				}
		}
		return;
	}
	
}
#end