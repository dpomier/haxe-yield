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
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentOption;
import yield.parser.idents.IdentRef;
import yield.parser.idents.ParentIdentData;
import yield.parser.tools.IdentCategory;

class EConstParser extends BaseParser
{
	
	public function run (e:Expr, subParsing:Bool, _c:Constant, ?ic:IdentChannel, initialized:Bool = false): Void {
		
		if (ic == null) ic = IdentChannel.Normal;
		
		// Resolve the identifier
		
		switch (_c) {
			
			case CIdent(_s):
				
				if (_s == "true" || _s == "false" || _s == "null") {
					return;
				}
				
				if (_s == "this") {
					
					m_we.addInstanceAccession(null, m_we.classComplexType, IdentRef.IEConst(e), ic, e.pos);
					
				} else {
					
					var exprCat:IdentCategory = m_we.getIdentCategoryOf(_s);
					
					switch (exprCat) {
						
						case IdentCategory.InstanceField(_t):
							
							var type:ComplexType = _t != null ? _t : macro:StdTypes.Dynamic; 
							
							m_we.addInstanceAccession(_s, type, IdentRef.IEConst(e), ic, e.pos);
							
						case IdentCategory.LocalVar(__of, __definition):
							
							var defIndex:Int = __definition.names.indexOf(_s);
							
							var type:ComplexType = __definition.types[defIndex];
							var initialized:Bool = initialized ? true : __definition.initialized[defIndex];
							
							if (__of == m_we) {
								
								m_we.addLocalAccession(_s, initialized, type, IdentRef.IEConst(e), ic, e.pos);
								
							} else {
								
								var identData:ParentIdentData = {
									identType:   IdentType.Accession(ic, __definition), 
									initialized: [initialized],
									types:       [type],
									names:       [_s], 
									ident:       IdentRef.IEConst(e),
									pos:         e.pos, 
									parent:      __of, 
									scope:       WorkEnv.currentScope, 
									env:         m_we,
									option:      __definition.option
								};
								
								if (__definition.option == IdentOption.KeepAsVar) {
									m_we.addParentAsVarDependencies(__of, identData);
								} else {
									m_we.addParentDependencies(__of);
									__of.addLocalAccession(_s, initialized, type, IdentRef.IEConst(e), ic, e.pos);
								}
								
								m_we.parentIdentStack.push(identData);
								
							}
							
						default:
					}
				}
				
			case _:
		}
		
		if (!subParsing) m_ys.addIntoBlock(e);
	}
	
}
#end