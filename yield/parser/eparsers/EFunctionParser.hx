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
import haxe.macro.Expr;
import yield.parser.Parser;
import yield.parser.env.WorkEnv;
import yield.generators.NameController;
import yield.parser.checks.TypeInferencer;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentOption;
import yield.parser.idents.IdentRef;
import yield.parser.idents.IdentRef.IdentRefTyped;
import yield.parser.tools.ExpressionTools;
import yield.parser.tools.MetaTools;
import yield.parser.tools.MetaTools.MetaToolsOption;

class EFunctionParser extends BaseParser {

	public function run (e:Expr, subParsing:Bool, _name:Null<String>, _f:Function, inlined:Bool): Void {
		
		#if (haxe_ver < 4.000)

		if (_name != null && StringTools.startsWith(_name, "inline_")) {
			_name   = _name.substr(7);
			inlined = true;
		}

		#end
		
		var safeName:String = NameController.anonymousFunction(m_we, _f, e.pos);
		
		MetaTools.option = MetaToolsOption.SkipNestedFunctions;
		
		if (!MetaTools.hasMeta(m_we.yieldKeyword, _f) || !Parser.parseFunction(safeName, _f, e.pos, m_we.getInheritedData())) {

			parseFun(_f, e.pos, true, false);

		}
		
		if (_name != null) { // If it isn't an anonymous function
			
			var ltype:Null<ComplexType> = TypeInferencer.tryInferFunction(_f);
			if (ltype == null) ltype	= macro:StdTypes.Dynamic;
			
			m_we.addLocalDefinition([_name], [true], [ltype], inlined, IdentRef.IEFunction(e), IdentChannel.Normal, [], e.pos);
			
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
					var v:Var		  = { name: arg.name, type: arg.type, expr: initValue };
					var evars:Expr	 = { expr: EVars([v]), pos: f.expr.pos };
					
					fExprs.unshift(evars);
				}
			}
			
			m_ys.eblockParser.run(f.expr, subParsing, fExprs, false, null, predefineNativeVars);
		}
		
		m_ys.yieldedScope = lOriginalScope;
	}

}
#end