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
import yield.parser.WorkEnv.Scope;
import yield.parser.tools.ExpressionTools;

class EIfParser extends BaseParser
{
	
	public function run (e:Expr, subParsing:Bool, _econd:Expr, _eif:Expr, _eelse:Null<Expr>, lastAlternativeScope:Scope = null): Void {
		
		if (!subParsing) m_ys.addIntoBlock(e);
		
		// Get alternative scopes
		
		var alternativeEconds:Array<Expr> = [];
		var alternativeExprs:Array<Expr>  = [];
		
		function parseEif (e:Expr) {
			switch (e.expr) {
				case ExprDef.EIf(_econd, _eif, _eelse):
					
					alternativeEconds.push(_econd);
					alternativeExprs.push(_eif);
					
					if (_eelse == null) {
						_eelse = { expr: EBlock([]), pos: _eif.pos };
						e.expr = ExprDef.EIf(_econd, _eif, _eelse);
					}
					
					parseEif(_eelse);
					
				default:
					
					alternativeExprs.push(e);
			}
		}
		
		parseEif(e);
		
		// Temporary shift the iterator's position
		
		var posInitial:UInt = m_ys.cursor;
		
		m_ys.moveCursor();
		
		// Parse scopes
		
		var alternativeCount:Int = alternativeExprs.length;
		var isDefault:Bool;
		var previousAlternativeScope:Scope = null;
		
		var lgotoPostEIf:Expr = { expr: null, pos: e.pos };
		var unYieldedScopes:Array<Array<Expr>> = [];
		
		for (i in 0...alternativeCount) {
			
			isDefault = i == alternativeCount - 1;
			
			var posFirst:UInt = m_ys.cursor;
			
			// parse econd
			if (!isDefault) {
				m_ys.parseOut(alternativeEconds[i], true, "Bool");
			}
			
			// parse eif/eelse
			previousAlternativeScope = m_ys.eblockParser.runFromExpr(alternativeExprs[i], false, true, previousAlternativeScope);
			previousAlternativeScope.defaultCondition = isDefault;
			
			if (m_ys.cursor == posFirst) {
				
				// let exprs in the EIf expression
				m_ys.iteratorBlocks[posFirst] = [];
				
				unYieldedScopes.push(ExpressionTools.checkIsInEBlock(alternativeExprs[i]));
				
			} else {
				
				// remove first sub-expression
				m_ys.spliceIteratorBlocks(posFirst, 1);
				
				// add goto sub-expressions
				var altExprs:Array<Expr> = ExpressionTools.checkIsInEBlock(alternativeExprs[i]);
				var ldefNext:Expr = { expr: null, pos: alternativeExprs[i].pos };
				#if (!display && !yield_debug_display)
				altExprs.unshift(ldefNext);
				m_ys.addSetAction(ldefNext, posFirst);
				#end
				
				// add goto post EIf
				m_ys.addIntoBlock(lgotoPostEIf);
				
				m_ys.moveCursor();
			}
		}
		
		// Shift back the iterator's position if relevant
		
		if (m_ys.cursor == posInitial + 1) {
			
			m_ys.spliceIteratorBlocks(m_ys.cursor, 1);
			
		} else {
			
			#if (!display && !yield_debug_display)
			if (subParsing) Context.fatalError("Missing return value", e.pos);
			#end
			
			// add goto post EIf
			#if (!display && !yield_debug_display)
			for (lexprs in unYieldedScopes) lexprs.push(lgotoPostEIf);
			m_ys.addGotoAction(lgotoPostEIf, m_ys.cursor);
			#end
		}
	}
	
}
#end