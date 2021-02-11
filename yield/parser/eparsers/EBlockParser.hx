/*
 * The MIT License
 * 
 * Copyright (C)2021 Dimitri Pomier
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
import haxe.macro.Expr;
import yield.parser.env.WorkEnv.Scope;
import yield.parser.idents.IdentRef.IdentRefTyped;
import yield.parser.tools.ExpressionTools;

class EBlockParser extends BaseParser {
	
	/**
	 * Wrap `e` into an EBlock expression if it isn't already one
	 */
	public function runFromExpr (e:Expr, subParsing:Bool, conditionalScope:Bool = false, alternativeScope:Scope = null, predefineNativeVars:Array<IdentRefTyped> = null): Scope {
		
		var lexprs:Array<Expr> = ExpressionTools.checkIsInEBlock(e);
		return run(e, subParsing, lexprs, conditionalScope, alternativeScope, predefineNativeVars);
	}
	
	public function run (e:Expr, subParsing:Bool, _exprs:Array<Expr>, conditionalScope:Bool = false, alternativeScope:Scope = null, predefineNativeVars:Array<IdentRefTyped> = null): Scope {
		
		var posOriginalIterator = m_ys.cursor;
		
		m_ys.moveCursor();
		
		var posFirstSubexpression = m_ys.cursor;
		
		var scope:Scope = m_we.openScope(conditionalScope, alternativeScope);
		
		// Predefine native variables
		if (predefineNativeVars != null)
			m_we.addLocalNativeDefinitions(predefineNativeVars);
		
		for (lexpr in _exprs)
			m_ys.parse(lexpr, subParsing);
		
		m_we.closeScope();
		
		if (m_ys.cursor == posFirstSubexpression) {
			
			m_ys.spliceIteratorBlocks(m_ys.cursor, 1);
			
			if (!subParsing) m_ys.addIntoBlock(e);
			
		} else {
			
			e.expr = EBlock(m_ys.iteratorBlocks[posFirstSubexpression]);
			if (!subParsing) m_ys.addIntoBlock(e, posOriginalIterator);
			
			m_ys.spliceIteratorBlocks(posFirstSubexpression, 1);
		}
		
		return scope;
	}
	
}
#end