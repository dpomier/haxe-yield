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
import yield.parser.env.WorkEnv;
import yield.parser.checks.TypeInferencer;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentOption;
import yield.parser.idents.IdentRef;

class EVarsParser extends BaseParser {
	
	public function run (e:Expr, subParsing:Bool, _vars:Array<Var>, ?ic:IdentChannel, ?options:Array<IdentOption>): Void {
		
		if (ic == null) {
			ic = IdentChannel.Normal;
		}
		
		if (options == null) {
			options = [];
		}
		
		var names:Array<String> = [];
		var initialized:Array<Bool> = [];
		var types:Array<ComplexType> = [];

		var isFinal:Bool = false;
		
		for (j in 0..._vars.length) {
			
			var typeInferred:Bool = false;

			#if (haxe_ver >= 4.000)
			isFinal = _vars[j].isFinal;
			#end
			
			if (!WorkEnv.isDynamicTarget()) {
				TypeInferencer.checkLocalVariableType(_vars[j], m_we, ic, e.pos); // Force typing because the type is required for member variables on static targets
				types.push(_vars[j].type != null ? _vars[j].type : macro:StdTypes.Dynamic);
			} else {
				
				if (_vars[j].type == null) {
					var inferred:Null<ComplexType> = TypeInferencer.tryInferExpr(_vars[j].expr, m_we, ic);
					if (inferred != null) {
						_vars[j].type = inferred;
					}
				}
				
				types.push(_vars[j].type);
			}
			
			m_ys.parseVar(_vars[j], true, ic);
			names.push(_vars[j].name);
			initialized.push(_vars[j].expr != null);
		}
		
		if (ic == IdentChannel.IterationOp || isFinal) {
			options.push(IdentOption.ReadOnly);
		}
		
		m_we.addLocalDefinition(names, initialized, types, false, IdentRef.IEVars(e), ic, options, e.pos);
		
		if (!subParsing) m_ys.addIntoBlock( e );
	}
	
}
#end