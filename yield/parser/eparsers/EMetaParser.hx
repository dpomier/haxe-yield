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
package yield.parser.eparsers;
import haxe.macro.Context;
import haxe.macro.Expr;
import yield.parser.eactions.Action;
import yield.parser.eactions.ActionParser;
import yield.parser.idents.IdentChannel;
import yield.parser.tools.IdentCategory;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
import yield.parser.checks.TypeInferencer;

class EMetaParser extends BaseParser {
	
	public function run (e:Expr, subParsing:Bool, _s:MetadataEntry, _e:Expr): Void {
		
		if (_s.name == m_we.yieldKeywork) {
			
			if (_s.params == null || _s.params.length == 0) {
				parseYieldMeta(e, subParsing, _s, _e);
				return;
			} else {
				
				var tooManyArgs:Bool = false;
				
				for (lparamExpr in _s.params) {
					
					var actions:Array<Action> = ActionParser.getAction(lparamExpr);
					
					if (actions != null) {
						
						m_ys.actionParser.executeAction(actions, _e);
						m_ys.addIntoBlock(e);
						return;
						
					} else {
						tooManyArgs = true;
					}
					
				}
				
				if (tooManyArgs) Context.fatalError("Too many arguments", e.pos);
			}
			
		} else {

			var inlined:Bool = _s.name == ":inline";

			m_ys.parseMetadataEntry(_s, true);
			m_ys.parse(_e, true, IdentChannel.Normal, inlined);
			if (!subParsing) m_ys.addIntoBlock(e);
		}
	}
	
	private function parseYieldMeta (e:Expr, subParsing:Bool, _s:MetadataEntry, _e:Expr): Void {
		
		switch (_e.expr) {
			
			case EReturn(__e):
				#if (!yield_debug_no_display && (display || yield_debug_display))
				m_ys.addDisplayDummy(e); // TODO parse __e to know the type when inferred typing
				#else
				switch (m_we.functionReturnKind) {
					case UNKNOWN(t, returns): 
						var rt = __e != null ? TypeInferencer.tryInferExpr(__e, m_we, IdentChannel.Normal) : macro:StdTypes.Void;
						returns.push(rt != null ? ComplexTypeTools.toType(rt) : null);
					case _:
				}
				m_ys.parse(__e, true);
				#end
			case EBreak:
				m_ys.registerBreakAction(e);
			default:
				Context.fatalError( "Unexpected " + m_we.yieldKeywork, e.pos );
		}
		
		m_ys.addIntoBlock(e);
		m_ys.moveCursor();
	}
	
}
#end