/*
 * The MIT License
 * 
 * Copyright (C)2018 Dimitri Pomier
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
package yield.parser.env;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import yield.parser.tools.ImportTools;

class ClassData {

	public var module           (default, null):Array<Type>;
	public var localClass       (default, null):ClassType;
	public var localType        (default, null):Type;
	public var localComplexType (default, null):ComplexType;
	public var isPrivate        (default, null):Bool;
	public var isAbstract       (default, null):Bool;
	public var abstractType     (default, null):Null<AbstractType>;
	public var classFields      (default, null):Array<Field>;
	public var imports          (default, null):Array<ImportExpr>;
	public var importedFields   (default, null):Array<String>;
	public var importedEnums    (default, null):Array<EnumType>;
	public var usings           (default, null):Array<Ref<ClassType>>;

	private inline function new () {

	}

	public static function of (ct:ClassType, t:Type):ClassData {

		var data = new ClassData();

		data.module = Context.getModule(Context.getLocalModule());
		data.localClass = ct;
		data.localType  = t;
		data.localComplexType = Context.toComplexType(t);

		switch (ct.kind) {
			case KAbstractImpl(_.get() => a):
				data.isAbstract   = true;
				data.abstractType = a;
			default: 
				data.isAbstract   = false;
				data.abstractType = null;
		}
		
		data.isPrivate = ct.isPrivate;
		
		data.classFields    = Context.getBuildFields();
		data.imports        = Context.getLocalImports();
		data.importedFields = ImportTools.getFieldShorthands(data.imports);
		data.importedEnums  = ImportTools.getEnumConstructors(data.imports, data.module);
		data.usings         = Context.getLocalUsing();

		return data;
	}

}

#end