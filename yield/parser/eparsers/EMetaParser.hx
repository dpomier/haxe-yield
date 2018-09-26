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
package yield.parser.eparsers;
import haxe.macro.Context;
import haxe.macro.Expr;
import yield.parser.eactions.Action;
import yield.parser.eactions.ActionParser;

class EMetaParser extends BaseParser
{
	
	public function run (e:Expr, subParsing:Bool, _s:MetadataEntry, _e:Expr): Void {
		
		if (_s.name == m_we.yieldKeywork) {
			
			if (_s.params == null || _s.params.length == 0) {
				parseYieldMeta(e, subParsing, _s, _e);
				return;
			} else {
				
				var tooManyArgs:Bool = false;
				
				for (lparamExpr in _s.params) {
					
					var action:Action = ActionParser.getAction(lparamExpr);
					
					if (action != null) {
						
						m_ys.actionParser.executeAction(action, _e);
						m_ys.addIntoBlock(e);
						return;
						
					} else {
						tooManyArgs = true;
					}
					
				}
				
				if (tooManyArgs) Context.fatalError("Too many arguments", e.pos);
			}
			
		} else {
			m_ys.parseMetadataEntry(_s, true);
			m_ys.parse(_e, true);
			if (!subParsing) m_ys.addIntoBlock(e);
		}
	}
	
	private function parseYieldMeta (e:Expr, subParsing:Bool, _s:MetadataEntry, _e:Expr): Void {
		
		switch (_e.expr) {
			
			case EReturn(__e):
				m_ys.parse(__e, true);
				
			case EBreak:
				m_ys.addBreakAction(e);
				
			default:
				Context.fatalError( "Unexpected " + m_we.yieldKeywork, e.pos );
		}
		
		m_ys.addIntoBlock(e);
		m_ys.moveCursor();
	}
	
}
#end