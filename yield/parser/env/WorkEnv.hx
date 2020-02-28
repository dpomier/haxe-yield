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
package yield.parser.env;
import yield.parser.tools.ImportTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.Function;
import haxe.macro.Type;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.AbstractType;
import yield.generators.DefaultGenerator;
import yield.parser.PositionManager.LinkedPosition;
import yield.parser.checks.InitializationChecker;
import yield.parser.checks.TypeInferencer;
import yield.parser.idents.*;
import yield.parser.idents.IdentRef.IdentRefTyped;
import yield.parser.tools.FieldTools;
import yield.parser.tools.IdentCategory;

typedef Scope = {
	var parent:Scope;
	var children:Array<Scope>;
	var level:UInt;
	var id:UInt;
	var localIdentStack:Array<Statement>;
	var conditional:Bool;
	var conditionalAlternatives:Array<Scope>;
	var defaultCondition:Bool;
}

enum ReturnType {
	ITERABLE(t:ComplexType);
	ITERATOR(t:ComplexType);
	BOTH(t:ComplexType);
	UNKNOWN(t:ComplexType, returns:Array<Type>);
}

/**
 * Data of the function being parsed.
 */
class WorkEnv {
	
	public var yieldKeywork  (default, null):String;
	public var yieldExplicit (default, null):Bool;
	public var yieldExtend   (default, null):Bool;
	
	public var currentScope (default, null):Scope;
	public var scopeCounter (default, null):UInt;
	
	public var classData (default, null):ClassData;
	
	public var functionName       (default, null):String;
	public var classField         (default, null):Field;
	public var functionDefinition (default, null):Function;
	public var functionReturnKind (default, null):ReturnType;
	public var yieldedType        (default, null):Null<ComplexType>;
	public var defaultYieldedValue (default, null):Expr;
	
	/**
	 * [ClassName, FunctionName, FunctionName1, ... FunctionNameN] where FunctionNameN is the parent of the current parsed function.
	 */
	public var functionsPack (default, null):Array<String>;
	
	public var localStack     (default, null):Array<Statement>;
	public var instanceStack  (default, null):Array<Statement>;
	public var parentStack    (default, null):Array<Statement>;
	public var parentDependencies	   (default, null):Array<WorkEnv>;
	public var parentAsVarDependencies (default, null):Array<{env:WorkEnv, identData:IdentData}>;
	
	public var functionArguments (default, null):Array<ArgIdentData>;
	
	public var gotoActions	(default, null):Array<LinkedPosition>;
	public var setActions	(default, null):Array<LinkedPosition>;
	public var breakActions	(default, null):Array<LinkedPosition>;
	
	public var parent (default, null):WorkEnv;

	public var generatedIteratorClass (default, null):TypeDefinition;
	
	public var requiredBySubEnv (default, null):Bool;
	public var requiresInstance (default, null):Bool;

	public var yieldMode:Bool;
	public var untypedMode:Bool;

	#if yield_debug
	@:allow(yield.parser.Parser)
	public var debug (default, null):Bool = false;
	#end
	
	public function new () {
		
		parentDependencies      = [];
		parentAsVarDependencies = [];
		parent = null;

		untypedMode = false;
	}
	
	public function setOptions (keywork:String, explicit:Bool, extend:Bool): Void {
		
		yieldKeywork  = keywork;
		yieldExplicit = explicit;
		yieldExtend   = extend;
	}
	
	public function setClassData (ct:ClassType, t:Type): Void {
		
		classData = ClassData.of(ct, t);

		functionsPack = [classData.localClass.name];
	}
	
	public function setFieldData (field:Field): Void {
		
		classField = field;
		currentScope  = {
			id    : 0,
			level : 0,
			parent: null,
			children: [],
			conditional            : false,
			conditionalAlternatives: null,
			defaultCondition       : false,
			localIdentStack: new Array<Statement>()
		};
		scopeCounter = 0;
		yieldMode    = true;
		requiredBySubEnv = false;
		requiresInstance = false;
	}
	
	public function setFunctionData (name:String, f:Function, returnKind:ReturnType, pos:Position): Void {
		
		// reset
		localStack    = new Array<Statement>();
		instanceStack = new Array<Statement>();
		parentStack   = new Array<Statement>();
		
		gotoActions  = new Array<LinkedPosition>();
		setActions   = new Array<LinkedPosition>();
		breakActions = new Array<LinkedPosition>();
		functionArguments = new Array<ArgIdentData>();
		
		// set data
		functionName = name;
		functionDefinition = f;
		functionReturnKind = returnKind;
		yieldedType = switch (returnKind) {
			case ITERABLE(t), ITERATOR(t), BOTH(t), UNKNOWN(t, _): t;
		};
		
		defaultYieldedValue = WorkEnv.getDefaultValue(yieldedType);
		
		// set arguments
		addConstructorArgs(f.args, pos);
		
		// init type definition
		generatedIteratorClass      = DefaultGenerator.makeTypeDefinition(this);
		generatedIteratorClass.pack = getExtraTypePath().pack;
	}

	public function updateYieldedType (type:ComplexType):Void {

		defaultYieldedValue.expr = WorkEnv.getDefaultValue(type).expr;

		functionReturnKind = switch functionReturnKind {
			case UNKNOWN(_, returns): UNKNOWN(type, returns);
			case ITERATOR(_): ITERATOR(type);
			case ITERABLE(_): ITERABLE(type);
			case BOTH(_): BOTH(type);
		}
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
			
			var data:IdentData = addLocalDefinition([arg.name], [true], [ltype], false, IdentRef.IEVars(evars), IdentChannel.Normal, [], evars.pos);
			
			functionArguments.push({ definition: data, originalArg: arg });
		}
	}
	
	public function getInheritedData (): WorkEnv {
		
		var we:WorkEnv = new WorkEnv();

		we.classData = classData;
		
		we.functionsPack = functionsPack.copy();
		we.functionsPack.push( functionName );

		we.parent        = this;
		we.classField    = classField;
		we.currentScope  = currentScope;
		we.untypedMode   = untypedMode;
		we.scopeCounter  = 0;
		we.setOptions(yieldKeywork, yieldExplicit, yieldExtend);
		
		#if yield_debug
		we.debug = debug;
		#end
		
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
	
	public function addParentAsVarDependencies (of:WorkEnv, data:IdentData): Void {
		
		if (this != of) {
			
			for (item in parentAsVarDependencies) {
				if (item.env == of && item.identData.names[0] == data.names[0])
					return;
			}
			
			parentAsVarDependencies.push({ env: of, identData: data });
			parent.addParentAsVarDependencies(of, data);
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
		
		var moduleName:String = (classData.isAbstract ? classData.abstractType.module : classData.localClass.module).split(".").pop();
		var className:String = classData.isAbstract ? classData.abstractType.name : classData.localClass.name;
		var isSubType:Bool = moduleName != className;
		
		var p = {
			pack : !classData.isAbstract ? classData.localClass.pack : classData.abstractType.pack,
			name : isSubType ? moduleName : generatedIteratorClass.name,
			sub  : isSubType ? generatedIteratorClass.name : null
		};
		
		if (classData.isPrivate && p.pack[p.pack.length - 1] == "_" + moduleName) {
			p.pack.pop();
		}
		
		return p;
	}
	
	public function openScope (isConditional:Bool = false, alternativeScope:Scope = null): Scope {
		
		scopeCounter += 1;

		var s:Scope = {
			id    : scopeCounter,
			level : currentScope.level + 1,
			parent: currentScope,
			children: [],
			conditional            : isConditional,
			conditionalAlternatives: null,
			defaultCondition       : false,
			localIdentStack: new Array<Statement>()
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
	
	public function addLocalDefinition (names:Array<String>, initialized:Array<Bool>, types:Array<ComplexType>, inlined:Bool, ident:IdentRef, ic:IdentChannel, options:Array<IdentOption>, pos:Position): IdentData {
		
		var data:IdentData = {
			names:       names, 
			initialized: initialized,
			types:       types,
			ident:       ident,
			channel:     ic,
			options:     options,
			scope:       currentScope,
			env:         this,
			pos:         pos
		};
		
		if (options.indexOf(ReadOnly) != -1) {
			for (i in 0...initialized.length) {
				if (!initialized[i]) Context.fatalError(names[i] + ' must be initialized to be readonly', pos);
			}
		}
		
		localStack.push(Statement.Definitions(data, inlined));
		currentScope.localIdentStack.push(Statement.Definitions(data, inlined));
		
		return data;
	}
	
	public function addLocalAccession (name:String, initialized:Bool, type:ComplexType, ident:IdentRef, ic:IdentChannel, pos:Position): Void {
		
		var defIdent:IdentData = getLocalDefinitionOf(name, ic);
		
		
		if (defIdent == null) {
			Context.fatalError("Unknown identifier : " + name, pos);
		}
		
		if (!initialized) {
			initialized = defIdent.initialized[defIdent.names.indexOf(name)];
		}
		
		var data:IdentData = {
			names:       [name], 
			initialized: [initialized],
			types:       [type],
			ident:       ident,
			channel:     ic,
			options:     defIdent.options,
			scope:       currentScope,
			env:         this,
			pos:         pos
		};
		
		if (!initialized) {
			if (!InitializationChecker.hasBeenInitialized(data, defIdent, data.scope))
				Context.fatalError("Local variable " + name + " used without being initialized", pos);
			else 
				data.initialized = [true];
		}
		
		localStack.push(Statement.Accession(data, defIdent));
		currentScope.localIdentStack.push(Statement.Accession(data, defIdent));
	}
	
	public function addInstanceAccession (field:Null<String>, type:Null<ComplexType>, ident:IdentRef, ic:IdentChannel, pos:Position): Void {
		
		var data:IdentData = {
			names:       field == null ? null : [field], 
			initialized: null,
			types:       [type],
			ident:       ident,
			channel:     ic,
			options:     [],
			scope:       currentScope,
			env:         this,
			pos:         pos
		};
		
		instanceStack.push(Statement.Accession(data, null));
		
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
					case EFunction(#if (haxe_ver >= 4.000 && haxe != "4.0.0-rc.3") FNamed(_name, _) #else _name #end, _f): 
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
			
			addLocalDefinition([lname], [true], [ident.type], false, ident.ref, IdentChannel.Normal, [IdentOption.KeepAsVar], lpos);
		}
	}
	
	public function addLocalThrow (): Void {
		
		localStack.push(Statement.Throw);
		currentScope.localIdentStack.push(Statement.Throw);
	}
	
	public function getLocalDefinitionOf (name:String, ic:IdentChannel): Null<IdentData> {
		
		var defType:Int = Statement.Definitions(null, false).getIndex();
		var i:Int = localStack.length;
		while (--i >= 0) {
			
			switch (localStack[i]) {
				case Statement.Definitions(_data, _inlined) if (_data.scope.id == currentScope.id || isParentScope(_data.scope, currentScope)):
					for (lname in _data.names) {
						if (lname == name) {
							return _data;
						}
					}
				case _:
			}
		}
		
		return parent != null ? parent.getLocalDefinitionOf(name, ic) : null;
	}
	
	public function getIdentCategoryOf (name:String, ic:IdentChannel): IdentCategory {
		
		var data:IdentData = getLocalDefinitionOf(name, ic);
		
		if (data != null) {
			return IdentCategory.LocalVar(data);
		} else {
			return FieldTools.resolveIdent(name, classData);
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
	
	public static function getDefaultValue (type:Null<ComplexType>): Expr {
		
		if (isDynamicTarget() || type == null)
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