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
package yield.parser.eparsers;
import haxe.macro.Context;
import haxe.macro.Expr;
import yield.parser.env.WorkEnv;
import yield.parser.env.WorkEnv.Scope;
import yield.parser.idents.IdentRef.IdentRefTyped;
import yield.parser.tools.ExpressionTools;
import yield.parser.tools.MetaTools;

class ESwitchParser extends BaseParser {
	
	public function run (e:Expr, subParsing:Bool, _e:Expr, _cases:Array<Case>, _edef:Null<Expr>): Void {
		
		// Parse subject
		
		m_ys.parseOut(_e, true, "Bool");
		if (!subParsing) m_ys.addIntoBlock(e);
		
		// Temporary shift the iterator position
		
		var posInitial:UInt = m_ys.cursor;
		
		m_ys.moveCursor();
		
		// Parse cases
		
		var yieldedCases:Bool = false;
		
		var lastCaseScope:Scope = null;
		
		var lgotoAfterSwitch:Expr = { expr: EConst(CIdent("null")), pos: _e.pos };
		
		for (lcase in _cases) {
			
			if (lcase.guard != null) m_ys.parseOut(lcase.guard, true, "Bool");
			
			if (lcase.expr == null) {
				lastCaseScope = m_we.openScope(true, lastCaseScope);
				lastCaseScope.defaultCondition = true; // switch may cover all possibilities without having a default case defined
				m_we.closeScope();
				continue;
			}
			
			var lexprs:Array<Expr> = ExpressionTools.checkIsInEBlock(lcase.expr);
			
			var predefineNativeVars:Array<IdentRefTyped> = [];
			
			// initialize params as variables (only if the case is yielded)
			if (lcase.values.length != 0) {
				
				var paramNames:Array<Expr> = [];
				
				if (lcase.values.length != 0)
					for (v in getParamsFromCase(lcase.values[0], m_we))
						paramNames.push(v);
				
				MetaTools.option = MetaToolsOption.SkipNestedFunctions;
				
				if (MetaTools.hasMetaExpr(m_we.yieldKeyword, lcase.expr)) {
					for (econst in paramNames) {
						
						predefineNativeVars.push({ ref: IdentRef.IEConst(econst), type: macro:StdTypes.Dynamic });
						
						var initValue:Expr = { expr: econst.expr, pos: econst.pos };
						var v:Var		  = { name: ExpressionTools.getConstIdent(econst), type: macro:StdTypes.Dynamic, expr: initValue };
						var evars:Expr	 = { expr: EVars([v]), pos: econst.pos };
						
						lexprs.unshift(evars);
					}
				} else {
					for (econst in paramNames) {
						predefineNativeVars.push({ ref: IdentRef.IEConst(econst), type: macro:StdTypes.Dynamic });
					}
				}
			}
			
			var posInitialCase:UInt = m_ys.cursor;
			lastCaseScope = m_ys.eblockParser.run(lcase.expr, false, lexprs, true, lastCaseScope, predefineNativeVars);
			lastCaseScope.defaultCondition = true; // switch may cover all possibilities without having a default case defined
			
			if (m_ys.cursor == posInitialCase) {
				
				m_ys.iteratorBlocks[m_ys.cursor] = [];
				
			} else {
				
				yieldedCases = true;
				
				var posFirstSub:UInt = posInitialCase;
				
				var lnewExprs:Array<Expr> = m_ys.iteratorBlocks[posFirstSub];
				
				// Goto first sub-expression
				#if (yield_debug_no_display || !display && !yield_debug_display) 
				var ldefineNextSubExpr:Expr  = { expr: null, pos: _e.pos };
				m_ys.registerSetAction(ldefineNextSubExpr, posFirstSub+1);
				lnewExprs.unshift(ldefineNextSubExpr);
				
				lcase.expr = { expr: EBlock( lnewExprs ), pos: lcase.expr.pos };
				m_ys.spliceIteratorBlocks(posFirstSub, 1);
				#end
				
				// Goto after the switch
				m_ys.addIntoBlock(lgotoAfterSwitch);
				
				m_ys.moveCursor();
				
			}
			
		}
		
		if (!yieldedCases) {
			
			m_ys.spliceIteratorBlocks(m_ys.cursor, 1);
			
		} else {
			
			#if (yield_debug_no_display || !display && !yield_debug_display)
			if (subParsing) Context.fatalError("Missing return value", e.pos);
			
			for (lcase in _cases) {
				if (lcase.expr == null) lcase.expr = lgotoAfterSwitch;
				else ExpressionTools.checkIsInEBlock(lcase.expr).push(lgotoAfterSwitch); // For non-yielded cases
			}
			
			m_ys.addIntoBlock(lgotoAfterSwitch, posInitial);
			
			m_ys.registerGotoAction(lgotoAfterSwitch, m_ys.cursor);
			#end
		}
		
		// Parse default
		
		if (_edef != null && _edef.expr != null) {
			var s = m_ys.eblockParser.runFromExpr(_edef, true, true, lastCaseScope);
			s.defaultCondition = true;
		}
	}
	
	private static function getParamsFromCase (value:Expr, env:WorkEnv): Array<Expr> {
		
		var params:Array<Expr> = [];
		
		switch (value.expr) {
			
			case ECall(_e, _params):
				for (larg in _params)
					for (p in getParamsFromCase(larg, env))
						params.push(p);
				
			case EBinop(_op, _e1, _e2) if (_op == Binop.OpArrow):
				for (p in getParamsFromCase(_e2, env))
						params.push(p);
				
			case EConst(_c):
				switch (_c) {
					case CIdent(_s):

						for (enumType in env.classData.importedEnums) {
							for (construct in enumType.constructs.keys()) {
								if (_s == construct) {
									return params;
								}
							}
						}
						params.push(value);
						
					default:
				}
				
			default:
		}
		return params;
	}
	
}
#end