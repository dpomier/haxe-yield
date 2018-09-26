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
import haxe.macro.ExprTools;
import yield.parser.eactions.ActionParser;
import yield.parser.idents.IdentChannel;
import yield.parser.tools.ExpressionTools;
import yield.parser.tools.MetaTools;
import yield.parser.tools.MetaTools.MetaToolsOption;

class EForParser extends BaseParser
{
	
	public function run (e:Expr, subParsing:Bool, _it:Expr, _expr:Expr): Void {
		
		var loopExprs:Array<Expr> = ExpressionTools.checkIsInEBlock(_expr);
		
		MetaTools.option = MetaToolsOption.SkipNestedFunctions;
		
		if (MetaTools.hasMetaExpr(m_we.yieldKeywork, _expr, true)) {
			runSplitMode(e, subParsing, _it, _expr, loopExprs);
		} else {
			runPreserveMode(e, subParsing, _it, _expr, loopExprs);
		}
	}
	
	private function runSplitMode (e:Expr, subParsing:Bool, _it:Expr, _expr:Expr, loopExprs:Array<Expr>): Void {
		
		var ewhileEcond:Expr = {expr: null, pos:e.pos};
		var ewhileE:Expr     = {expr: _expr.expr, pos:e.pos};
		var ewhile:Expr      = {expr: EWhile(ewhileEcond,ewhileE, true), pos:e.pos};
		
		var updateExprs:Array<Expr> = new Array<Expr>();
		
		switch (_it.expr) {
			#if (haxe_ver < 4.000)
			case EIn(__e1, __e2):
			#else
			case EBinop(OpIn, __e1, __e2):
			#end
				
				var opIdentName:String = ExpressionTools.getConstIdent(__e1);
				var localVar:Expr = __e1;
				
				var opIdent:Expr = {
					expr: EConst(CIdent(opIdentName)), 
					pos: e.pos
				};
				
				ActionParser.addActionToExpr(Action.DefineChannel(IdentChannel.IterationOp), opIdent, m_we);
				
				switch (__e2.expr) {
					case EBinop(___op, ___e1, ___e2): 
						
						switch (___op) {
							case OpInterval: // x...n
								
								// initialization
								
								var opVars:Array<Var> = [{
									name: opIdentName,
									type: macro:StdTypes.Int,
									expr: ___e1
								}];
								
								m_ys.evarsParser.run({expr:EVars(opVars), pos:e.pos}, false, opVars, IdentChannel.IterationOp);
								
								// loop
								
								ewhileEcond.expr = EBinop(OpLt, opIdent, ___e2);
								
								updateExprs.push({
									expr: EVars([{
										name: opIdentName,
										type: macro:StdTypes.Int,
										expr: {expr:EUnop(OpIncrement, true, opIdent), pos:e.pos}
									}]),
									pos: __e1.pos
								});
								
							default:
						}
						
					default:
						
						// initialization
						
						var getIteratorField = macro yield.macrotime.Tools.getIterator;
						
						var lexprOp:Expr = {
							expr: EConst(CIdent("null")),
							pos:__e2.pos
						};
						
						var opVars:Array<Var> = [{
							name: opIdentName,
							type: macro:StdTypes.Dynamic,
							expr: lexprOp
						}];
						
						m_ys.evarsParser.run({expr:EVars(opVars), pos:e.pos}, false, opVars, IdentChannel.IterationOp);
						
						m_ys.parseOut(__e2, true);
						lexprOp.expr = ECall(getIteratorField, [__e2]); // Note that it is not parsed
						
						// loop
						
						ewhileEcond.expr = ECall({expr:EField(opIdent, "hasNext"), pos: _it.pos}, []);
						
						updateExprs.push({
							expr: EVars([{
								name: opIdentName,
								type: macro:StdTypes.Dynamic,
								expr: {expr:ECall({expr:EField(opIdent, "next"),pos:__e1.pos}, []), pos:__e1.pos}
							}]),
							pos: __e1.pos
						});
				}
				
			default:
		}
		
		for (v in updateExprs) loopExprs.unshift(v);
		
		e.expr = ewhile.expr;
		m_ys.ewhileParser.run(ewhile, subParsing, ewhileEcond, ewhileE, true, true);
	}
	
	private function runPreserveMode (e:Expr, subParsing:Bool, _it:Expr, _expr:Expr, loopExprs:Array<Expr>): Void {
		
		switch (_it.expr) {
			#if (haxe_ver < 4.000)
			case EIn(__e1, __e2):
			#else
			case EBinop(OpIn, __e1, __e2):
			#end
				
				m_ys.parseOut(__e2, true);
				
				var ltypeE1:ComplexType = switch (__e2.expr) {
					case ExprDef.EBinop(___op, ___e1, ___e2):
						
						if (___op == Binop.OpInterval)
							macro:StdTypes.Int;
						else 
							macro:StdTypes.Dynamic;
						
					default:
						macro:StdTypes.Dynamic;
				}
				
				m_ys.eblockParser.run(_expr, true, loopExprs, true, null, [{ ref: IdentRef.IEConst(__e1), type: ltypeE1 }]);
				
				if (!subParsing) m_ys.addIntoBlock(e);
				
			default: 
		}
	}
	
}
#end