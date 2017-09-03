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
package yield.parser.tools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Field;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.TypeTools;
import yield.parser.checks.TypeInferencer;

class FieldTools
{
	
	public static function makeFieldFromVar (v:Var, access:Array<Access>, initialValue:Expr, pos:Position): Field {
		return {
			name	: v.name,
			doc		: null,
			access	: access,
			kind	: FVar(v.type, initialValue),
			pos		: pos,
			meta	: null
		};
	}
	
	public static function makeField (name:String, access:Array<Access>, initialValue:Expr, pos:Position): Field {
		return {
			name	: name,
			doc		: null,
			access	: access,
			kind	: FVar(null, initialValue),
			pos		: pos,
			meta	: null
		};
	}
	
	public static function makeFieldAssignation (fieldName:String, value:Expr): Expr {
		return {
			expr: EBinop(
				OpAssign, 
				{ expr : EField( {expr:EConst(CIdent("this")), pos:value.pos} , fieldName), pos	 : value.pos},
				value
			),
			pos : value.pos
		}
	}
	
	public static function getImportedFields (): Array<String> {
		
		var importedExprs:Array<ImportExpr> = Context.getLocalImports();
		var ret:Array<String> = new Array<String>();
		
		for (iexpr in importedExprs) {
			switch (iexpr.mode) {
				case IAsName(alias):
					ret.push(alias);
				case IAll:
					
					var tp:TypePath = {
						name : iexpr.path[iexpr.path.length - 1].name,
						pack : [for (i in 0...iexpr.path.length-1) iexpr.path[i].name]
					};
					
					var complexType:ComplexType = ComplexType.TPath(tp);
					var t:Type = Context.resolveType(complexType, iexpr.path[iexpr.path.length - 1].pos );
					
					var classType:ClassType = TypeTools.getClass(t);
					
					var statics:Array<ClassField> = classType.statics.get();
					
					for (i in 0...statics.length)
						if (statics[i].isPublic)
							ret.push( statics[i].name );
					
				case INormal:
				default:
			}
		}
		
		return ret;
	}
	
	/**
	 * Determine the nature of the identifier `e`.
	 */
	public static function resolveIdent (s:String, classType:ClassType, classFields:Array<Field>, importedFields:Array<String>): IdentCategory {
		
		var lcat:Null<IdentCategory>;
		
		// Members
		
		lcat = getInstanceField(classFields, classType, s);
		if (lcat != null) return lcat;
		
		// Statics
		
		lcat = getStaticField(classFields, classType, s);
		if (lcat != null) return lcat;
		
		// Imported fields
		
		if (importedFields == null) importedFields = getImportedFields();
		
		lcat = getImportedField(importedFields, s);
		if (lcat != null) return lcat;
		
		return IdentCategory.Unknown;
	}
	
	private static function getInstanceField (classFields:Array<Field>, classType:ClassType, name:String): Null<IdentCategory> {
		
		for (i in 0...classFields.length)
			if (classFields[i].name == name && (classFields[i].access == null || classFields[i].access.indexOf(Access.AStatic) == -1))
				return IdentCategory.InstanceField(TypeInferencer.tryInferField(classFields[i].kind));
		
		if (classType.superClass != null) {
			var cf:Null<ClassField> = TypeTools.findField( classType.superClass.t.get(), name, false );
			if (cf != null) return IdentCategory.InstanceField(null);
		}
		
		return null;
	}
	
	private static function getStaticField (classFields:Array<Field>, classType:ClassType, name:String): Null<IdentCategory> {
		
		for (i in 0...classFields.length)
			if (classFields[i].name == name && classFields[i].access != null && classFields[i].access.indexOf(Access.AStatic) != -1)
				return IdentCategory.InstanceStaticField(TypeInferencer.tryInferField(classFields[i].kind));
		
		if (classType.superClass != null) {
			var cf:Null<ClassField> = TypeTools.findField( classType.superClass.t.get(), name, true );
			if (cf != null) return IdentCategory.InstanceStaticField(null);
		}
		
		return null;
	}
	
	private static inline function getImportedField (importedFields:Array<String>, name:String): Null<IdentCategory> {
		
		var i:Int = importedFields.indexOf(name);
		return i != -1 ? IdentCategory.ImportedField(null) : null;
	}
	
}
#end