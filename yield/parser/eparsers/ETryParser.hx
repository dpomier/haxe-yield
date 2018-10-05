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
import haxe.macro.Expr;
import yield.parser.WorkEnv.Scope;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentOption;
import yield.parser.tools.ExpressionTools;

class ETryParser extends BaseParser
{
	
	public function run (e:Expr, subParsing:Bool, _e:Expr, _catches:Array<Catch>): Void {
		
		if (subParsing) {
			runPreserveMode(e, _e, _catches);
		} else {
			runSplitMode(e, subParsing, _e, _catches);
		}
	}
	
	private function runPreserveMode (e:Expr, _e:Expr, _catches:Array<Catch>): Void {
		
		m_ys.parseOut(_e, true);
		
		var previousAlternativeScope:Scope = null;
		
		for (lcatch in _catches) {
			m_ys.parseComplexType(lcatch.type, true);
			previousAlternativeScope = m_ys.eblockParser.runFromExpr(lcatch.expr, true, true, previousAlternativeScope, [{ ref: IdentRef.ICatch(lcatch), type: lcatch.type }]);
		}
	}
	
	private function runSplitMode (e:Expr, subParsing:Bool, _e:Expr, _catches:Array<Catch>): Void {
		
		var posOriginalIterator = m_ys.cursor;
		
		m_ys.moveCursor();
		
		var lgotoPost:Expr = { expr: null, pos: e.pos };
		
		// Parse catches
		
		var previousCatchScope:Scope = null;
		
		for (lcatch in _catches) {
			previousCatchScope = parseCatch(lcatch, lgotoPost, previousCatchScope);
		}
		
		#if (!display && !yield_debug_display) 
		
		// Parse try block
		
		var posFirstTry = m_ys.cursor;
		
		// goto the first try statement expressions
		e.expr = null;
		m_ys.addGotoAction(e, posFirstTry);
		
		if (!subParsing) m_ys.addIntoBlock(e, posOriginalIterator);
		
		// Wrap each try-sub expressions in the ETry
		
		var ltryExprs:Array<Expr> = ExpressionTools.checkIsInEBlock(_e);
		m_ys.eblockParser.run(_e, false, ltryExprs, true, previousCatchScope);
		
		var posEndTries = m_ys.cursor;
		
		for (i in posFirstTry...m_ys.cursor+1) {
			
			m_ys.iteratorBlocks[i] = [{
				expr: ETry({expr: EBlock(m_ys.iteratorBlocks[i]),pos : _e.pos}, _catches),
				pos: e.pos
			}];
		}
		
		var posPostETry = posEndTries + 1;
		
		// Goto after the try-catch
		
		m_ys.addIntoBlock(lgotoPost);
		
		m_ys.moveCursor();
		
		// Setup Goto actions
		
		m_ys.addGotoAction(lgotoPost, posPostETry);
		#end
	}
	
	private function parseCatch (c:Catch, gotoPostTry:Expr, previousCatchScope:Scope): Scope {
		
		previousCatchScope = m_we.openScope(true, previousCatchScope);
		
		switch (c.type) {
			case (macro:Dynamic) | (macro:StdTypes.Dynamic):
				previousCatchScope.defaultCondition = true;
			default:
		}
		
		// Add catch-argument as property
		var initializationValue:Expr = {expr:EConst(CIdent(c.name)), pos:c.expr.pos};
		var ldefinition:Expr = {
			expr: EVars([{name: c.name, type: c.type, expr: initializationValue}]),
			pos: c.expr.pos
		};
		m_we.addLocalDefinition([c.name], [true], [c.type], false, IdentRef.IEVars(ldefinition), IdentChannel.Normal, [], ldefinition.pos);
		
		
		var posOriginal = m_ys.cursor;
		
		var posFirst = m_ys.cursor;
		
		m_ys.parseComplexType(c.type, true);
		m_ys.parse(c.expr, false);
		
		// Replace the body with Goto action to the first catch sub-expressions
		#if (!display && !yield_debug_display) 
		var lgotoNext:Expr   = { expr: null, pos: c.expr.pos };
		c.expr = {expr:EBlock([ldefinition, lgotoNext]), pos:c.expr.pos};
		m_ys.addGotoAction(lgotoNext, posFirst);
		#end
		
		// Goto after the try-catch
		m_ys.addIntoBlock(gotoPostTry);
		
		m_ys.moveCursor();
		
		m_we.closeScope();
		
		return previousCatchScope;
	}
	
}
#end