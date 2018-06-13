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
import yield.parser.Parser;
import haxe.macro.Expr;
import yield.generators.NameController;
import yield.parser.checks.TypeInferencer;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentOption;
import yield.parser.idents.IdentRef;
import yield.parser.idents.IdentRef.IdentRefTyped;
import yield.parser.tools.ExpressionTools;
import yield.parser.tools.MetaTools;
import yield.parser.tools.MetaTools.MetaToolsOption;

class EFunctionParser extends BaseParser
{

	public function run (e:Expr, subParsing:Bool, _name:Null<String>, _f:Function): Void {
		
		var isInlined = _name != null && StringTools.startsWith(_name, "inline_");
		
		if (isInlined) {
			_name = _name.substr(7);
		}
		
		var safeName:String = NameController.anonymousFunction(m_we, _f, e.pos);
		
		MetaTools.option = MetaToolsOption.SkipNestedFunctions;
		
		if (!MetaTools.hasMeta(WorkEnv.YIELD_KEYWORD, _f) || !Parser.parseFunction(safeName, _f, e.pos, m_we.getInheritedData())) {
			parseFun(_f, e.pos, true, false);
		}
		
		if (_name != null) { // If it isn't an anonymous function
			
			var ltype:Null<ComplexType> = TypeInferencer.tryInferFunction(_f);
			if (ltype == null) ltype	= macro:StdTypes.Dynamic;
			
			if (subParsing) { // If the declaration is wrapped in another expression
				
				// insert the declaration just before this expression
				var insertedDeclaration:Expr = { expr: EFunction(_name, _f), pos: e.pos };
				
				m_we.addLocalDefinition([_name], [true], [ltype], isInlined, IdentRef.IEFunction(insertedDeclaration), IdentChannel.Normal, IdentOption.None, insertedDeclaration.pos);
				m_ys.addIntoBlock(insertedDeclaration);
				
				// change this expr to identify the function rather than declare it
				e.expr = EConst(CIdent(_name));
				m_ys.parseOut(e, true);
				
			} else {
				
				m_we.addLocalDefinition([_name], [true], [ltype], isInlined, IdentRef.IEFunction(e), IdentChannel.Normal, IdentOption.None, e.pos);
			}
			
		}
		
		if (!subParsing) m_ys.addIntoBlock(e);
	}
	
	public function parseFun (f:Function, pos:Position, subParsing:Bool, yieldedScope:Bool = true): Void {
		
		var lOriginalScope:Bool = m_ys.yieldedScope;
		m_ys.yieldedScope = yieldedScope;
		
		if (f.params != null) {
			for (lparam in f.params) {
				m_ys.parseTypeParamDecl(lparam, subParsing);
			}
		}
		
		if (f.ret != null) m_ys.parseComplexType(f.ret, subParsing);
		
		if (f.expr != null) {
			
			var fExprs:Array<Expr> = ExpressionTools.checkIsInEBlock(f.expr);
			
			var predefineNativeVars:Array<IdentRefTyped> = [];
			
			// Define arguments as local variables
			if (f.args.length != 0) {
				
				for (arg in f.args) {
					
					var ltype:ComplexType = TypeInferencer.tryInferArg(arg);
					if (ltype == null) ltype = macro:StdTypes.Dynamic;
					predefineNativeVars.push({ ref: IdentRef.IArg(arg, f.expr.pos), type: ltype });
					
					m_ys.parseFunctionArg(arg, true);
					
					if (!WorkEnv.isDynamicTarget()) {
						TypeInferencer.checkArgumentType(arg, pos);
					}
					
					var initValue:Expr = { expr: EConst(CIdent(arg.name)), pos: f.expr.pos };
					var v:Var          = { name: arg.name, type: arg.type, expr: initValue };
					var evars:Expr     = { expr: EVars([v]), pos: f.expr.pos };
					
					fExprs.unshift(evars);
				}
			}
			
			m_ys.eblockParser.run(f.expr, subParsing, fExprs, false, null, predefineNativeVars);
		}
		
		m_ys.yieldedScope = lOriginalScope;
	}

}
#end