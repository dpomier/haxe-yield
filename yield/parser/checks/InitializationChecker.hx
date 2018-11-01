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
#if (macro || display)
package yield.parser.checks;
import yield.parser.env.WorkEnv.Scope;
import yield.parser.idents.IdentData;
import yield.parser.idents.Statement;

class InitializationChecker {
	
	public static function hasBeenInitialized (accession:IdentData, definition:IdentData, currentScope:Scope, previousScopes:Array<Scope> = null): Bool {
		
		var info:{definitionReached:Bool} = { definitionReached: false };
		
		// Ignore previous scope
		
		if (previousScopes == null) previousScopes = [];
		
		previousScopes.push(currentScope);
		
		if (isInitializedInScope( accession, definition, currentScope, info )) {
			return true;
		}
		
		var childList:Array<Scope> = [];
		
		for (c in currentScope.children) childList.push(c);
		
		// Run through the various paths until reach the definition
		
		var i:Int = childList.length;
		var child:Scope;
		while (--i != -1) {
			
			child = childList[i];
			if (previousScopes.indexOf(child) != -1) continue;
			
			if (!child.conditional) {
				
				previousScopes.push(child);
				if (hasBeenInitialized( accession, definition, child, previousScopes )) {
					return true;
				}
				
			} else {
				
				var result:Bool = true;
				var defaultDefined:Bool = false;
				
				for (s in child.conditionalAlternatives) {
					
					if (previousScopes.indexOf(s) != -1) continue;
					
					previousScopes.push(s);
					
					if (result) {
						
						if (s.defaultCondition) defaultDefined = true;
						
						if (!hasBeenInitialized(accession, definition, s, previousScopes)) {
							result = false;
						}
					}
				}
				
				if (result && defaultDefined) return true;
			}
		}
		
		// Parent's scope
		if (!info.definitionReached && currentScope.parent != null && previousScopes.indexOf(currentScope.parent) == -1) {
			if (currentScope.conditional) 
				for (alt in currentScope.conditionalAlternatives)
					previousScopes.push(alt);
			return hasBeenInitialized(accession, definition, currentScope.parent, previousScopes);
		} else {
			return false;
		}
	}
	
	private static function isInitializedInScope (accession:IdentData, definition:IdentData, scope:Scope, info:{ definitionReached:Bool }): Bool {
		
		var j:Int = scope.localIdentStack.length;
		var statement:Statement;
		while (--j != -1) {
			statement = scope.localIdentStack[j];
			
			switch statement {
				
				case Statement.Definitions(_data, _inlined):
					if (_data == definition) {
						
						info.definitionReached = true;
						return _data.initialized[_data.names.indexOf(accession.names[0])];
					}
					
				case Statement.Accession(_data, _definition):
					if (_definition == definition) {
						return true; // stop the research, this ident will do the rest.
					}
					
				case Statement.Throw:
					return true;
			}
		}
		
		return false;
	}
	
}
#end