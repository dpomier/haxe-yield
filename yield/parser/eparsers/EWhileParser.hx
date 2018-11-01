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

class EWhileParser extends BaseParser
{
	
	private static var continueStatements:Array<Array<Expr>> = [];
	private static var breakStatements:Array<Array<Expr>>	= [];
	
	public function addContinue (e:Expr): Void {
		if (continueStatements.length != 0 && continueStatements[continueStatements.length - 1] != null) {
			continueStatements[continueStatements.length - 1].push(e);
		}
	}
	
	public function addBreak (e:Expr): Void {
		if (breakStatements.length != 0) {
			breakStatements[breakStatements.length - 1].push(e);
		}
	}
	
	public function run (e:Expr, subParsing:Bool, _econd:Expr, _e:Expr, _normalWhile:Bool, forceSplit:Bool = false): Void {
		
		if (subParsing) {
			runPreserveMode(e, subParsing, _econd, _e, _normalWhile, forceSplit);
		} else {
			runSplitMode(e, subParsing, _econd, _e, _normalWhile, forceSplit);
		}
	}
	
	private function runPreserveMode (e:Expr, subParsing:Bool, _econd:Expr, _e:Expr, _normalWhile:Bool, forceSplit:Bool = false): Void {
		
		m_ys.parseOut(_econd, true, "Bool");
		m_ys.parseOut(_e, true);
	}
	
	private function runSplitMode (e:Expr, subParsing:Bool, _econd:Expr, _e:Expr, _normalWhile:Bool, forceSplit:Bool = false): Void {
		
		continueStatements.push([]);
		breakStatements.push([]);
		
		m_ys.parseOut(_econd, true, "Bool");
		
		// While process
		
		var posOriginalDeclaration:Int = m_ys.cursor;
		
		var originalPosApart:Bool = false;
		
		if (m_ys.iteratorBlocks[posOriginalDeclaration].length != 0 || !_normalWhile) {
			originalPosApart = true;
			m_ys.moveCursor();
		}
		
		var posWhileDeclaration:Int = m_ys.cursor;
		
		m_ys.moveCursor();
		
		var posFirstSubExpression:Int = m_ys.cursor;
		
		m_ys.eblockParser.runFromExpr(_e, false, true);
		
		if (!forceSplit && m_ys.cursor == posFirstSubExpression) { // If there is no sub-yield expression
			
			if (originalPosApart) {
				m_ys.spliceIteratorBlocks(m_ys.cursor-1, 2);
			} else {
				m_ys.spliceIteratorBlocks(m_ys.cursor, 1);
			}
			
			if (!subParsing) m_ys.addIntoBlock(e);
			
			continueStatements.pop();
			breakStatements.pop();
			
		} else {
			
			#if (!display && !yield_debug_display) 
			if (subParsing) Context.fatalError("Missing return value", e.pos);
			
			var posLastWhilePart:Int = m_ys.cursor;
			var posAfterWhile:Int	= m_ys.cursor+1;
			
			// goto actions
			var lgotoWhileDecl:Expr    = { expr: null, pos: _e.pos };
			var lgotoFirstSubExpr:Expr = { expr: null, pos: _e.pos };
			var lgotoAfterWhile:Expr   = { expr: null, pos: _e.pos };
			
			
			// Append in posOriginal goto while declaration
			if (originalPosApart) {
				if (_normalWhile) m_ys.addIntoBlock(lgotoWhileDecl, posOriginalDeclaration);
				else {
					m_ys.addIntoBlock(lgotoFirstSubExpr, posOriginalDeclaration);
					_normalWhile = true;
				}
			}
			
			// While declaration with body: goto first sub expression, otherwise goto after the While
			e.expr = EWhile(_econd, lgotoFirstSubExpr, _normalWhile);
			m_ys.addIntoBlock(e, posWhileDeclaration);
			
			m_ys.addIntoBlock(lgotoAfterWhile, posWhileDeclaration);
			
			// Append in posLastWhilePart goto the While declaration
			m_ys.addIntoBlock(lgotoWhileDecl, posLastWhilePart);
			
			m_ys.moveCursor();
			
			
			// Setup actions
			
			m_ys.registerGotoAction( lgotoWhileDecl, posWhileDeclaration );
			m_ys.registerGotoAction( lgotoFirstSubExpr, posFirstSubExpression );
			m_ys.registerGotoAction( lgotoAfterWhile, posAfterWhile );
			
			// Setup break and continue statements
			
			var continues:Array<Expr> = continueStatements.pop();
			var breaks:Array<Expr>	= breakStatements.pop();
			
			for (lexpr in continues) {
				m_ys.registerGotoAction( lexpr, posWhileDeclaration );
			}
			
			for (lexpr in breaks) {
				m_ys.registerGotoAction( lexpr, posAfterWhile );
			}
			
			#end
		}
		
	}
	
}
#end