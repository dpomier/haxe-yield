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
package yield.parser.tools;
import haxe.macro.Expr.ImportMode;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr.Position;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.TypePath;
import haxe.macro.Expr.ImportExpr;

class ImportTools {
	
	public static function getFieldShorthands (imports:Array<ImportExpr>): Array<String> {
		
		var ret = new Array<String>();
		
		for (iexpr in imports) {
			switch (iexpr.mode) {
				case IAsName(alias):
					ret.push(alias);
				default:
			}
		}
		
		return ret;
	}

	public static function getEnumConstructors (imports:Array<ImportExpr>, module:Array<Type>): Array<EnumType> {

		var enums = new Array<EnumType>();

		inline function extractEnum (type:Type, into:Array<EnumType>):Void {
			switch (type) {
				case TEnum(t, params): into.push(t.get());
				case _: null;
			}
		}

		// from module

		for (type in module) {
			extractEnum(type, enums);
		}

		// from imports

		for (iexpr in imports) {
			switch (iexpr.mode) {
				case INormal, IAsName(_):

					var module:String = iexpr.path[0].name;

					var name:String;
					for (i in 1...iexpr.path.length) {
						name = iexpr.path[i].name;
						module += "." + name;
						if (name.charAt(0) != name.charAt(0).toLowerCase()) {
							break;
						}
					}

					var modules:Array<Type> = Context.getModule(module);

					if (modules != null)
						for (type in modules)
							if (type != null)
								extractEnum(type, enums);
					
				case IAll:
					// TODO
			}
		}

		return enums;
	}

	public static function isImported (type:Array<String>, ?localImports:Array<ImportExpr>):Bool {

		if (localImports == null) {
			localImports = Context.getLocalImports();
		}

		var imported = false;

		for (localImport in localImports) {

			var isAll:Bool = switch (localImport.mode) {
				case INormal, IAsName(_): false;
				case IAll:

					var	firstLetter:String = {
						var lastPart:String = localImport.path[localImport.path.length - 1].name;
						var i = 0;
						while (lastPart.charAt(i) == "_") {
							i++;
						}
						lastPart.charAt(i);
					};
					
					if (firstLetter != "" && firstLetter == firstLetter.toUpperCase()) {
						true;
					} else {
						false;
					};
			};

			if (localImport.path.length == type.length || isAll && localImport.path.length == type.length - 1) {
				
				var i = localImport.path.length;
				while (--i >= 0) {
					if (localImport.path[i].name != type[i]) {
						break;
					}
				}
				if (i < 0) {
					imported = true;
					break;
				}

			}
		}

		return imported;
	}
}
#end