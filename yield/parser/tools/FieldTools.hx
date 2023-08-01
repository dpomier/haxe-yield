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
package yield.parser.tools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Field;
import haxe.macro.Type;
import haxe.macro.Type.ClassField;
import haxe.macro.Type.ClassType;
import haxe.macro.TypeTools;
import yield.parser.checks.TypeInferencer;

class FieldTools {
	
	public static function makeFieldFromVar (v:Var, access:Array<Access>, initialValue:Null<Expr>, pos:Position): Field {
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
	
	public static function makeFunctionField (name:String, access:Array<Access>, f:Function, pos:Position): Field {
		return {
			name	: name,
			doc		: null,
			access	: access,
			kind	: FFun(f),
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
	
	/**
	 * Determine the nature of the identifier `e`.
	 */
	public static function resolveIdent (s:String, classData:yield.parser.env.ClassData): IdentCategory {
		
		var lcat:Null<IdentCategory>;
		
		// Members
		
		lcat = getInstanceField(classData.classFields, classData.localClass, s);
		if (lcat != null) return lcat;
		
		// Statics
		
		lcat = getStaticField(classData.classFields, classData.localClass, s);
		if (lcat != null) return lcat;
		
		// Imported fields
		
		lcat = getImportedField(classData.importedFields, s);
		if (lcat != null) return lcat;
		
		// Used fields
		
		lcat = getUsedField(classData.usings, s);
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
				return IdentCategory.InstanceStaticField(TypeInferencer.tryInferField(classFields[i].kind), classType);
		
		return null;
	}
	
	private static inline function getImportedField (importedFields:Array<String>, name:String): Null<IdentCategory> {
		
		var i:Int = importedFields.indexOf(name);
		return i != -1 ? IdentCategory.ImportedField(null) : null;
	}

	private static function getUsedField (usings:Array<Ref<ClassType>>, name:String): Null<IdentCategory> {

		for (ref in usings) {
			var ct = ref.get();
			for (field in ct.statics.get()) {
				if (field.name == name) {
					return IdentCategory.ImportedField(null);
				}
			}
		}

		return null;
	}
	
	public static function toString (field:Field): String {
		
		return switch (field.kind) {
			
			case FieldType.FFun(_f):
				
				"function " + field.name + " (" + [ for (arg in _f.args) (arg.opt ? "?" : "") + arg.name + (arg.type == null ? "" : ":" + ComplexTypeTools.toString(arg.type)) + (arg.value == null ? "" : " = " + ExprTools.toString(arg.value)) ].join(", ") + ") " + ExprTools.toString(_f.expr);
				
			case FieldType.FVar(_t, _e):
				
				"var " + field.name + (_t == null ? "" : ":" + ComplexTypeTools.toString(_t)) + (_e == null ? "" : " = " + ExprTools.toString(_e)) + ";";
				
			case FieldType.FProp(_get, _set, _t, _e):
				
				"var " + field.name + " (" + _get + ", " + _set + ")" + (_t == null ? "" : ":" + ComplexTypeTools.toString(_t)) + (_e == null ? "" : " = " + ExprTools.toString(_e)) + ";";
		}
	}
	
}
#end