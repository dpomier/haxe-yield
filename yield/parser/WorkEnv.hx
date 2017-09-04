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
package yield.parser;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.Function;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.ClassType;
import yield.generators.DefaultGenerator;
import yield.parser.PositionManager.LinkedPosition;
import yield.parser.checks.InitializationChecker;
import yield.parser.checks.TypeInferencer;
import yield.parser.idents.*;
import yield.parser.idents.IdentRef.IdentRefTyped;
import yield.parser.idents.ParentIdentData;
import yield.parser.tools.FieldTools;
import yield.parser.tools.IdentCategory;

typedef Scope = {
	var parent:Scope;
	var children:Array<Scope>;
	var level:UInt;
	var id:UInt;
	var localIdentStack:Array<IdentData>;
	var conditional:Bool;
	var conditionalAlternatives:Array<Scope>;
	var defaultCondition:Bool;
}

enum RetType {
	DYNAMIC;
	ITERABLE;
	ITERATOR;
}

/**
 * Data of the function being parsed.
 */
class WorkEnv
{
	
	public static var YIELD_KEYWORD  (default, null):String;
	public static var YIELD_EXPLICIT (default, null):Bool;
	
	public static var currentScope (default, null):Scope;
	
	public var classType 		(default, null):ClassType;
	public var classField 		(default, null):Field;
	public var classFunction 	(default, null):Function;
	public var isAbstract 		(default, null):Bool;
	public var abstractType 	(default, null):AbstractType;
	public var classComplexType (default, null):ComplexType;
	public var classFields 		(default, null):Array<Field>;
	public var importedFields 	(default, null):Array<String>;
	
	public var fieldName 		(default, null):String;
	public var functionRetType 	(default, null):RetType;
	public var returnType 		(default, null):ComplexType;
	public var defaultReturnType (default, null):Expr;
	
	/**
	 * [ClassName, FunctionName, FunctionName1, ... FunctionNameN] where FunctionNameN is the parent of the current parsed function.
	 */
	public var functionsPack (default, null):Array<String>;
	
	public var localIdentStack		(default, null):Array<IdentData>;
	public var instanceIdentStack	(default, null):Array<IdentData>;
	public var parentDependencies	(default, null):Array<WorkEnv>;
	public var parentAsVarDependencies (default, null):Array<{env:WorkEnv, identData:ParentIdentData}>;
	public var parentIdentStack		(default, null):Array<ParentIdentData>;
	
	public var functionArguments (default, null):Array<ArgIdentData>;
	
	public var gotoActions	(default, null):Array<LinkedPosition>;
	public var setActions	(default, null):Array<LinkedPosition>;
	public var breakActions	(default, null):Array<LinkedPosition>;
	
	public var parent (default, null):WorkEnv;

	public var generatedIteratorClass (default, null):TypeDefinition;
	
	public var requiredBySubEnv (default, null):Bool;
	public var requiresInstance (default, null):Bool;

	public var yieldMode:Bool;
	
	private static var scopeCounter:UInt;
	
	public function new () {
		
		classType = Context.getLocalClass().get();
		classComplexType = Context.toComplexType(Context.getLocalType());
		
		switch (Context.getLocalType()) {
			case haxe.macro.Type.TInst(_.get() => _t, _params):
				switch (_t.kind) {
					case KAbstractImpl(_.get() => __a):
						abstractType = __a;
						isAbstract   = true;
					default: 
						isAbstract = false;
				}
			default:
				isAbstract = false;
		}
		
		classFields    = Context.getBuildFields();
		importedFields = FieldTools.getImportedFields();
		functionsPack  = [classType.name];
		
		parentDependencies      = [];
		parentAsVarDependencies = [];
		parent = null;
	}
	
	public function setOptions (yieldKeywork:String, yieldExplicit:Bool): Void {
		
		YIELD_KEYWORD  = yieldKeywork;
		YIELD_EXPLICIT = yieldExplicit;
	}
	
	public function setFieldData (f:Field, fun:Function): Void {
		
		classField    = f;
		classFunction = fun;
		currentScope  = {
			id    : 0,
			level : 0,
			parent: null,
			children: [],
			conditional            : false,
			conditionalAlternatives: null,
			defaultCondition       : false,
			localIdentStack: new Array<IdentData>()
		};
		scopeCounter = 0;
		yieldMode    = true;
		requiredBySubEnv = false;
		requiresInstance = false;
	}
	
	public function setFunctionData (name:String, f:Function, functionRetType:RetType, returnType:ComplexType, pos:Position): Void {
		
		// reset
		localIdentStack    = new Array<IdentData>();
		instanceIdentStack = new Array<IdentData>();
		parentIdentStack   = new Array<ParentIdentData>();
		
		gotoActions  = new Array<LinkedPosition>();
		setActions   = new Array<LinkedPosition>();
		breakActions = new Array<LinkedPosition>();
		functionArguments = new Array<ArgIdentData>();
		
		// set data
		fieldName = name;
		this.returnType = returnType;
		this.functionRetType = functionRetType;
		
		defaultReturnType = WorkEnv.getDefaultValue(returnType);
		
		// set arguments
		addConstructorArgs(f.args, pos);
		
		// init type definition
		generatedIteratorClass      = DefaultGenerator.makeTypeDefinition(this);
		generatedIteratorClass.pack = getExtraTypePath().pack;
	}
	
	private function addConstructorArgs (args:Array<FunctionArg>, pos:Position): Void {
		
		for (arg in args) {
			
			if (!WorkEnv.isDynamicTarget()) {
				TypeInferencer.checkArgumentType(arg, pos);
			}
			
			var initValue:Expr = { expr: EConst(CIdent("null")), pos: pos };
			var v:Var          = { name: arg.name, type: arg.type, expr: initValue };
			var evars:Expr     = { expr: EVars([v]), pos: pos };
			
			var ltype:Null<ComplexType> = TypeInferencer.tryInferArg(arg);
			if (ltype == null) ltype = macro:StdTypes.Dynamic;
			
			var identData:IdentData = addLocalDefinition([arg.name], [true], [ltype], IdentRef.IEVars(evars), IdentChannel.Normal, IdentOption.None, evars.pos);
			
			functionArguments.push({ definition: identData, originalArg: arg });
		}
	}
	
	public function alreadyPrecessed (): Bool {
		return classType.meta.has(":yield_processed");
	}
	
	public function markHasProcessed (): Void {
		classType.meta.add(":yield_processed", [], classType.pos);
	}
	
	public function getInheritedData (): WorkEnv {
		
		var we:WorkEnv = new WorkEnv();
		
		we.functionsPack = functionsPack.copy();
		we.functionsPack.push( fieldName );
		we.parent        = this;
		we.isAbstract    = isAbstract;
		we.abstractType  = abstractType;
		we.classField    = classField;
		we.classFunction = classFunction;
		
		return we;
	}
	
	public function addParentDependencies (of:WorkEnv): Void {
		
		if (this != of && parentDependencies.indexOf(of) == -1) {
			parentDependencies.push(of);
			parent.addParentDependencies(of);
			parent.requiredBySubEnv = true;
		} else {
			of.requiredBySubEnv = true;
		}
	}
	
	public function addParentAsVarDependencies (of:WorkEnv, ident:ParentIdentData): Void {
		
		if (this != of) {
			
			for (item in parentAsVarDependencies) {
				if (item.env == of && item.identData.names[0] == ident.names[0])
					return;
			}
			
			parentAsVarDependencies.push({ env: of, identData: ident });
			parent.addParentAsVarDependencies(of, ident);
		}
	}
	
	public function getParentCount (): Int {
		return parent != null ? 1 + parent.getParentCount() : 0;
	}
	
	private function addInstanceDependency (): Void {
		
		requiresInstance = true;
		
		if (parent != null) {
			parent.addInstanceDependency();
		}
	}
	
	public function getGeneratedComplexType (): ComplexType {
		return TPath(getExtraTypePath());
	}
	
	public function getExtraTypePath (): TypePath {
		
		return {
			pack : !isAbstract ? classType.pack : abstractType.pack,
			name : generatedIteratorClass.name,
			sub  : null
		};
	}
	
	public function openScope (isConditional:Bool = false, alternativeScope:Scope = null): Scope {
		
		var s:Scope = {
			id    : ++scopeCounter,
			level : currentScope.level + 1,
			parent: currentScope,
			children: [],
			conditional            : isConditional,
			conditionalAlternatives: null,
			defaultCondition       : false,
			localIdentStack: new Array<IdentData>()
		};
		
		if (s.conditional) {
			
			if (alternativeScope == null) {
				s.conditionalAlternatives = [s];
			} else {
				s.conditionalAlternatives = alternativeScope.conditionalAlternatives;
				s.conditionalAlternatives.push(s);
			}
		}
		
		currentScope.children.push(s);
		
		currentScope = s;
		
		return currentScope;
	}
	
	public function closeScope (): Void {
		currentScope = currentScope.parent;
	}
	
	/**
	 * @return Is `p` parent of `c`.
	 */
	public function isParentScope (p:Scope, c:Scope): Bool {
		
		if (c.parent == null) {
			return false;
		} else if (p.id == c.parent.id) {
			return true;
		} else {
			return isParentScope( p, c.parent);
		}
	}
	
	public function addLocalDefinition (names:Array<String>, initialized:Array<Bool>, types:Array<ComplexType>, ident:IdentRef, ic:IdentChannel, option:IdentOption, pos:Position): IdentData {
		
		var identData:IdentData = {
			identType:   IdentType.Definition(ic), 
			initialized: initialized,
			types:       types,
			env:         this,
			names:       names, 
			ident:       ident,
			pos:         pos,
			scope:       currentScope,
			option:      option
		};
		
		localIdentStack.push(identData);
		currentScope.localIdentStack.push(identData);
		
		return identData;
	}
	
	public function addLocalAccession (name:String, initialized:Bool, type:ComplexType, ident:IdentRef, ic:IdentChannel, pos:Position): Void {
		
		var defIdent:IdentData = getLocalDefinitionOf(name, ic);
		
		
		if (defIdent == null) {
			Context.fatalError("Unknown identifier : " + name, pos);
		}
		
		if (!initialized) {
			initialized = defIdent.initialized[defIdent.names.indexOf(name)];
		}
		
		var identData:IdentData = {
			identType:   IdentType.Accession(ic, defIdent), 
			initialized: [initialized],
			types:       [type],
			env:         this,
			names:       [name], 
			ident:       ident,
			pos:         pos,
			scope:       currentScope,
			option:      IdentOption.None
		};
		
		if (!initialized) {
			if (!InitializationChecker.hasBeenInitialized(identData, defIdent, identData.scope))
				Context.fatalError("Local variable " + name + " used without being initialized", pos);
			else 
				identData.initialized = [true];
		}
		
		localIdentStack.push(identData);
		currentScope.localIdentStack.push(identData);
	}
	
	public function addInstanceAccession (field:Null<String>, type:ComplexType, ident:IdentRef, ic:IdentChannel, pos:Position): Void {
		
		instanceIdentStack.push({
			identType:   IdentType.Accession(ic, null), 
			initialized: null,
			types:       [type],
			env:         this,
			names:       field == null ? null : [field], 
			ident:       ident,
			pos:         pos,
			scope:       currentScope,
			option:      IdentOption.None
		});
		
		addInstanceDependency();
	}
	
	/**
	 * Add local definitions which must be preserved as local variables.
	 */
	public function addLocalNativeDefinitions (definitions:Array<IdentRefTyped>): Void {
		
		for (ident in definitions) {
			
			var lname:String;
			var lpos:Position;
			
			switch (ident.ref) {
				
				case IdentRef.IEConst(eRef): switch (eRef.expr) {
					case EConst(_c):
						
						switch (_c) {
							case CIdent(_s) if (_s != "null" && _s != "false" && _s != "true" && _s != "this"): 
								lname = _s;
								lpos  = eRef.pos;
							case _: continue;
						};
						
					default: continue;
				}
				
				case IdentRef.ICatch(cRef): 
					lname = cRef.name;
					lpos  = cRef.expr.pos;
				
				case IdentRef.IEField(eRef): switch (eRef.expr) {
					case EField(_e, _field): 
						lname = _field;
						lpos  = eRef.pos;
					default: continue;
				}
				
				case IdentRef.IEFunction(eRef): switch (eRef.expr) {
					case EFunction(_name, _f): 
						lname = _name;
						lpos  = eRef.pos;
					default: continue;
				}
				
				case IdentRef.IEVars(eRef): switch (eRef.expr) {
					case EVars(_vars) if (_vars.length == 1): 
						lname = _vars[0].name;
						lpos  = eRef.pos;
					default: continue;
				}
				
				case IdentRef.IArg(aRef, pos): 
					lname = aRef.name;
					lpos  = pos;
			}
			
			addLocalDefinition([lname], [true], [ident.type], ident.ref, IdentChannel.Normal, IdentOption.KeepAsVar, lpos);
		}
	}
	
	public function addLocalThrow (pos:Position): Void {
		
		var identData:IdentData = {
			identType:   IdentType.Throw, 
			initialized: null,
			types:       null,
			env:         this,
			names:       null, 
			ident:       null,
			pos:         pos,
			scope:       currentScope,
			option:      IdentOption.None
		};
		
		localIdentStack.push(identData);
		currentScope.localIdentStack.push(identData);
	}
	
	public function getLocalDefinitionOf (name:String, ic:IdentChannel): Null<IdentData> {
		
		var defType:Int = IdentType.Definition(ic).getIndex();
		var i:Int = localIdentStack.length;
		while (--i >= 0) {
			
			if (localIdentStack[i].identType.getIndex() == defType &&
				(localIdentStack[i].scope.id == currentScope.id || isParentScope(localIdentStack[i].scope, currentScope))
				) {
				
				for (lname in localIdentStack[i].names) {
					if (lname == name) {
						return localIdentStack[i];
					}
				}
			}
			
		}
		
		return parent != null ? parent.getLocalDefinitionOf(name, ic) : null;
	}
	
	public function getIdentCategoryOf (name:String): IdentCategory {
		
		var identData:IdentData = getLocalDefinitionOf(name, IdentChannel.Normal);
		
		if (identData != null) {
			return IdentCategory.LocalVar(identData.env, identData);
		} else {
			return FieldTools.resolveIdent(name, classType, classFields, importedFields);
		}
	}
	
	public static function isDynamicTarget (): Bool {
		
		return Context.defined("neko")
			|| Context.defined("js")
			|| Context.defined("php")
			|| Context.defined("python")
			|| Context.defined("lua")
			|| Context.defined("flash6")
			|| Context.defined("flash7")
			|| Context.defined("flash8");
	}
	
	public static function getDefaultValue (type:ComplexType): Expr {
		
		if (isDynamicTarget())
			return macro null;
		
		switch (type) {
			
			case (macro:Int) | (macro:StdTypes.Int):
				
				return macro 0;
				
			case (macro:Float) | (macro:StdTypes.Float):
				
				if (!Context.defined("flash"))
					return macro 0.0;
				else
					return macro Math.NaN;
				
			case (macro:Bool) | (macro:StdTypes.Bool):
				
				return macro false;
				
			default:
				
				return macro null;
		}
	}
	
}
#end