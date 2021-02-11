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
import haxe.macro.Context;
import yield.parser.idents.Statement;
import haxe.macro.Expr;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentOption;
import yield.parser.idents.IdentRef;
import yield.parser.idents.IdentData;
import yield.parser.env.WorkEnv;
import yield.parser.tools.IdentCategory;

class EConstParser extends BaseParser {
	
	public function run (e:Expr, subParsing:Bool, _c:Constant, ?ic:IdentChannel, initialized = false, beingModified = false): Void {
		
		if (ic == null) ic = IdentChannel.Normal;
		
		// Resolve the identifier
		
		switch (_c) {
			
			case CIdent(_s):
				
				if (_s == "true" || _s == "false" || _s == "null") {
					return;
				}
				
				if (_s == "this") {
					
					m_we.addInstanceAccession(null, m_we.classData.localComplexType, IdentRef.IEConst(e), ic, e.pos);
					
				} else {
					
					var exprCat:IdentCategory = m_we.getIdentCategoryOf(_s, ic);
					
					switch (exprCat) {
						
						case IdentCategory.InstanceField(_t):
							
							m_we.addInstanceAccession(_s, _t, IdentRef.IEConst(e), ic, e.pos);
							
						case IdentCategory.LocalVar(__definition):
							
							var defIndex:Int = __definition.names.indexOf(_s);
							
							var type:ComplexType = __definition.types[defIndex];
							var initialized:Bool = initialized ? true : __definition.initialized[defIndex];
							
							
							if (beingModified && __definition.options.indexOf(ReadOnly) != -1) {
								
								if (__definition.options.indexOf(IsVarLoop) != -1) {
									
									Context.error('Loop variable cannot be modified', e.pos);
									
								} else {
									
									Context.error('Cannot access field or identifier $_s for writing', e.pos);
								}
							}
							
							if (__definition.env == m_we) {
								
								m_we.addLocalAccession(_s, initialized, type, IdentRef.IEConst(e), ic, e.pos);
								
							} else {
								
								var data:IdentData = {
									names: [_s],
									initialized: [initialized],
									types: [type],
									ident: IdentRef.IEConst(e),
									channel: ic,
									options: __definition.options.copy(),
									scope: m_we.currentScope,
									env: m_we,
									pos: e.pos
								};
								
								if (__definition.options.indexOf(IdentOption.KeepAsVar) != -1) {
									m_we.addParentAsVarDependencies(__definition.env, data);
								} else {
									m_we.addParentDependencies(__definition.env);
									__definition.env.addLocalAccession(_s, initialized, type, IdentRef.IEConst(e), ic, e.pos);
								}
								
								m_we.parentStack.push(Statement.Accession(data, __definition));
								
							}
							
						case IdentCategory.InstanceStaticField(_t, _c):
							
							e.expr = EField(Context.parse(_c.module + "." + _c.name, e.pos), _s);
							
						case IdentCategory.ImportedField(_t):
						case IdentCategory.Unknown:
					}
				}
				
			case _:
		}
		
		if (!subParsing) m_ys.addIntoBlock(e);
	}
	
}
#end