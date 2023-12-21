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
package yield.generators;
import haxe.macro.ExprTools;
import haxe.macro.MacroStringTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Position;
import haxe.macro.Expr.TypeDefinition;
import haxe.macro.Type;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.TypeParameter;
import haxe.macro.TypeTools;
import yield.generators.NameController;
import yield.parser.env.WorkEnv;
import yield.parser.env.WorkEnv.Scope;
import yield.parser.YieldSplitter.IteratorBlockData;
import yield.parser.idents.IdentChannel;
import yield.parser.idents.IdentData;
import yield.parser.idents.IdentOption;
import yield.parser.idents.IdentRef;
import yield.parser.idents.Statement;
import yield.parser.tools.ExpressionTools;
import yield.parser.tools.FieldTools;
import yield.parser.tools.IdentCategory;
import haxe.macro.Printer;
#if (haxe_ver >= 4.000)
using haxe.macro.PositionTools;
#end

class DefaultGenerator {
	
	private static var extraTypeCounter:UInt = 0;
	
	private static var typeDefinitionStack:Array<TypeDefinition> = [];
	
	public static function makeTypeDefinition (env:WorkEnv): TypeDefinition {
		
		var iteratorClassName:String = NameController.extraTypeName(env, ++extraTypeCounter);
		
		var c = macro class $iteratorClassName {
			#if debug
			function toString ():String {
				return "function" + $v{new Printer().printFunction(env.functionDefinition)};
			}
			#end
		}
		c.pos = env.classData.localClass.pos;
		c.meta = env.classData.localClass.meta.get().copy();
		
		return c;
	}
	
	/**
	 * Generate the extra-type representing the iterator blocks, then add it into the queue of type definition.
	 * @return Returns the expression which instantiates the generated extra-type.
	 */
	public static function add (ibd:IteratorBlockData, pos:Position, env:WorkEnv, eager:Bool): Expr {

		var bd:BuildingData = new BuildingData(env.generatedIteratorClass, env.getExtraTypePath(), ibd);
		
		initTypeMetas(bd, pos);
		initTypeParams(bd, env, pos);
		
		initIteratorActions(bd, env, pos);
		
		initParentDependencies(bd, env, pos);
		initParentAsVarDependencies(bd, env, pos);
		initInstanceDependency(bd, env, pos);
		initIteratorInitialisations(bd, env, ibd, pos);
		initIteratorMethods(bd, env, ibd, pos);
		initConstructor(bd, pos);
		
		allowAccessToPrivateFields(env, pos);
		initInstanceAccessions(env);
		initParentAccessions(env);
		
		initVariableFields(bd, env);
		initIterativeFunctions(bd, env, ibd);

		#if yield_debug
		if (env.debug) {
			trace(new Printer().printTypeDefinition( bd.typeDefinition ));
		}
		#end

		if (eager) 
			Context.defineType( bd.typeDefinition );
		else
			typeDefinitionStack.push( bd.typeDefinition );
		
		initInstanceFunctionBody(bd, pos);

		return bd.instanceFunctionBody;
	}
	
	/**
	 * Define all the type definitions from the queue.
	 */
	public static function run (env:WorkEnv): Void {
		
		var usings:Array<TypePath> = [];
		var c:ClassType;
		
		var tp:TypePath;
		var moduleName:String;
		for (cref in Context.getLocalUsing()) {
			
			c = cref.get();
			
			switch (c.kind) {
				case ClassKind.KNormal | ClassKind.KGeneric | ClassKind.KGenericBuild:
					
					moduleName = c.module.substr(c.module.lastIndexOf(".") + 1);
					
					if (moduleName == c.name) {
						tp = {
							name:c.name,
							pack:c.pack
						};
					} else {
						tp = {
							name:moduleName,
							pack:c.pack,
							sub:c.name
						};
					}
					
					usings.push(tp);
					
				default:
			}
		}
		
		Context.defineModule(Context.getLocalClass().get().module, typeDefinitionStack, env.classData.imports, usings);
		
		typeDefinitionStack = new Array<TypeDefinition>();
	}
	
	private static function addProperty (bd:BuildingData, name:String, access:Array<Access>, type:Null<ComplexType>, pos:Position): Void {
		
		bd.typeDefinition.fields.push({
			name:   name,
			access: access,
			kind:   FVar( type != null ? type : macro:StdTypes.Dynamic, null ),
			pos:	pos,
			doc:	null,
			meta:   null
		});
	}
	
	private static function addMethod (bd:BuildingData, name:String, access:Array<Access>, args:Array<FunctionArg>, ret:ComplexType, expr:Expr, pos:Position, metadata:Null<Metadata> = null): Void {
		
		var fn:Function = {
			args:   args,
			ret:	ret,
			expr:   expr,
			params: null
		}
		
		bd.typeDefinition.fields.push({
			name:   name,
			doc:	null,
			access: access,
			kind:   FFun( fn ),
			pos:	pos,
			meta:   metadata
		});
	}
	
	private static function addMeta (bd:BuildingData, name:String, ?params:Array<Expr>, pos:Position): Void {
		
		bd.typeDefinition.meta.push({
			name:   name,
			params: params,
			pos:	pos
		});
	}
	
	private static function initParentDependencies (bd:BuildingData, env:WorkEnv, pos:Position): Void {
		
		for (dependence in env.parentDependencies) {
			
			// Add the argument of the parent as a field
			
			var dependenceName:String = NameController.fieldParent(env, dependence);
			
			addProperty(bd, dependenceName, [APrivate], dependence.getGeneratedComplexType(), pos);
			
			var constructorArgName:String = NameController.argParent(env, dependence);
			
			bd.constructorArgs.push({
				name:  constructorArgName, 
				opt:   false, 
				type:  dependence.getGeneratedComplexType(),
				value: null, 
				meta:  null
			});
			
			bd.constructorBlock.push(macro $i{dependenceName} = $i{constructorArgName});
			
			// Pass the parent through arguments
			
			if (dependence == env.parent) {
				bd.givenArguments.push({
					expr: EConst(CIdent("this")),
					pos:  pos
				});
			} else {
				bd.givenArguments.push({
					expr: EField( {expr: EConst(CIdent("this")), pos: pos}, dependenceName),
					pos:  pos
				});
			}
			
		}
	}
	
	private static function initParentAsVarDependencies (bd:BuildingData, env:WorkEnv, pos:Position): Void {
		
		for (dependence in env.parentAsVarDependencies) {
			
			// Add the local variable as a field
			
			var fieldName:String = NameController.parentVar(dependence.identData.names[0], dependence.identData.scope, dependence.identData.channel, dependence.env.getParentCount());
			
			addProperty(bd, fieldName, [APrivate], dependence.identData.types[0], pos);
			
			var constructorArgName:String = NameController.argParentAsVar(fieldName);
			
			bd.constructorArgs.push({
				name:  constructorArgName, 
				opt:   false, 
				type:  dependence.identData.types[0],
				value: null, 
				meta:  null
			});
			
			bd.constructorBlock.push(macro $i{fieldName} = $i{constructorArgName});
			
			// Pass the local variable through arguments
			
			if (dependence.env == env.parent) {
				
				var econst:Expr = switch (dependence.identData.ident) {
					case IdentRef.IEConst(eRef): { expr: eRef.expr, pos: eRef.pos };
					default: null;
				}
				
				bd.givenArguments.push(econst);
				
				dependence.env.addLocalAccession(dependence.identData.names[0], dependence.identData.initialized[0], dependence.identData.types[0], IdentRef.IEConst(econst), dependence.identData.channel, econst.pos);
				
			} else {
				bd.givenArguments.push({
					expr: EField( {expr: EConst(CIdent("this")), pos: pos}, fieldName),
					pos: pos
				});
			}
		}
	}
	
	private static function initInstanceDependency (bd:BuildingData, env:WorkEnv, pos:Position): Void {
		
		// instance of the class
		
		if (env.requiresInstance) {
			
			// Add the argument of the instance as a field
			
			var lInstanceCT:ComplexType = !env.classData.isAbstract ? env.classData.localComplexType : TypeTools.toComplexType(env.classData.abstractType.type);
			
			addProperty(bd, NameController.fieldInstance(), [APrivate], lInstanceCT, pos);
			
			bd.constructorArgs.push({
				name:  NameController.argInstance(), 
				opt:   false, 
				type:  lInstanceCT, 
				value: null, 
				meta:  null
			});
			
			bd.constructorBlock.push(macro $i{NameController.fieldInstance()} = $i{NameController.argInstance()});
			
			// Pass the instance through arguments
			
			if (env.parent != null) {
				
				var lexpr:Expr = { expr: EConst(CIdent("this")), pos: pos };
				
				env.parent.addInstanceAccession(null, env.parent.getGeneratedComplexType(), IdentRef.IEConst(lexpr), IdentChannel.Normal, lexpr.pos);
				
				bd.givenArguments.push(lexpr);
				
			} else {
				
				if (env.parent == null) {
					
					bd.givenArguments.push({
						expr: EConst(CIdent("this")),
						pos:  pos
					});
					
				} else {
					
					bd.givenArguments.push({
						expr: EField( {expr: EConst(CIdent("this")), pos: pos}, NameController.fieldInstance()),
						pos:  pos
					});
				}
			}
		}
	}

	private static function isVoid (t:ComplexType):Bool {
		return switch t {
			case (macro:StdTypes.Void): true;
			case _: false;
		}
	}
	
	private static function initIteratorInitialisations (bd:BuildingData, env:WorkEnv, ibd:IteratorBlockData, pos:Position): Void {
		
		var nextMethodType:ComplexType = ComplexType.TFunction([macro:Void], env.yieldedType);
		
		addProperty(bd, NameController.fieldCursor(), [APrivate], macro:StdTypes.Int, pos);
		if (!isVoid(env.yieldedType))
			addProperty(bd, NameController.fieldCurrent(), [APrivate], env.yieldedType, pos);
		addProperty(bd, NameController.fieldIsConsumed(), [APrivate], macro:StdTypes.Bool, pos); 
		addProperty(bd, NameController.fieldCompleted(), [APrivate], macro:StdTypes.Bool, pos); 
		
		// Initialize arguments
		
		for (argData in env.functionArguments) {
			
			var newArgName:String = NameController.argArgument(argData.originalArg);
			var constructorArg:FunctionArg;
			
			// in extra-type constructor
			
			bd.constructorArgs.push({
				name:  newArgName,
				meta:  argData.originalArg.meta,
				opt:   false,
				type:  argData.originalArg.type,
				value: null
			});
			
			switch (argData.definition.ident) {
				case IdentRef.IEVars(eRef):
					
					switch (eRef.expr) {
						case EVars(_vars):
							for (v in _vars) v.expr = { expr: EConst(CIdent( newArgName )), pos: v.expr.pos };
							bd.constructorBlock.push(eRef);
						default:
					}
					
				default: throw "irrelevant ident reference : " + argData.definition.ident;
			}
			
			// in new call
			
			if (env.parent != null) {
				argData.originalArg.name = newArgName; // modify the name of the original argument as arg-name to avoid collisions with potential operative variables
			}
			
			bd.givenArguments.push({ expr:EConst(CIdent(argData.originalArg.name)), pos:argData.definition.pos });
		}
		
		// Initialize properties
		
		var exprs = [];
		
		for (i in 0...ibd.length) {
			exprs.push({expr:EConst(CIdent( NameController.iterativeFunction(i) )), pos:pos});
		}
		
		bd.constructorBlock.push(macro $i{NameController.fieldCursor()}	 = -1);

		if (!isVoid(env.yieldedType))
			bd.constructorBlock.push(macro $i{NameController.fieldCurrent()} = $e{env.defaultYieldedValue});
		bd.constructorBlock.push(macro $i{NameController.fieldIsConsumed()} = true);
		bd.constructorBlock.push(macro $i{NameController.fieldCompleted()}  = false);
	}
	
	private static function initIteratorMethods (bd:BuildingData, env:WorkEnv, ibd:IteratorBlockData, pos:Position): Void {

		var iterationMetadata:Metadata = [{ name: ":keep", params: [], pos: pos }];
		
		var lcase:Array<Case> = [for (i in 0...bd.lastSequence + 1) {
			values : [{ expr: EConst(CInt(Std.string(i))), pos: pos }],
			guard : null,
			expr: { expr: ExprDef.ECall({ expr: EConst(CIdent(NameController.iterativeFunction(i))), pos: pos}, []), pos: pos }
		}];
		
		var lswitch:Expr = { expr: ExprDef.ESwitch(macro (++$i{NameController.fieldCursor()}), lcase, macro ${env.defaultYieldedValue}), pos: pos };
		
		var lsetCurrent = if (!isVoid(env.yieldedType)) {
			macro $i{NameController.fieldCurrent()} = $lswitch;
		} else {
			lswitch;
		}

		var lprocess = if (env.positionMapping) {
			var file = #if (haxe_ver >= 4.000) pos.toLocation().file.toString() #else Context.getPosInfos(pos).file #end;
			macro try {
				${lsetCurrent};
			} #if (haxe_ver >= 4.100) catch(e:haxe.ValueException) {
				throw new haxe.ValueException(e.value, new haxe.Exception($v{file} + ":" + _line_ + ": " + e.message));
			} catch(e:haxe.Exception) {
				#if (haxe_ver >= 4.200)
				throw new haxe.exceptions.PosException(e.message, {
					lineNumber: _line_,
					fileName: $v{file},
					methodName: $v{env.classField.name},
					className: $v{env.classData.localClass.name}
				});
				#else
				throw $v{file} + ":" + _line_ + ": " + e.message;
				#end
			} #else catch(e:Any) {
				throw e;
			} #end
		} else {
			lsetCurrent;
		}

		// public function hasNext():Bool

		var body:Expr = {
			expr: EBlock([
			  macro if (!$i{NameController.fieldIsConsumed()}) return true;
					else if ($i{NameController.fieldCursor()} < $v{bd.lastSequence}) {
						$lprocess;
						if (!$i{NameController.fieldCompleted()}) { $i{NameController.fieldIsConsumed()} = false; return true; }
						else return false;
					},
			  macro return false
			]), 
			pos: pos
		};
		
		addMethod(bd, "hasNext", [APublic], [], macro:StdTypes.Bool, body, pos, iterationMetadata);
		
		// public function next():???

		var returnDefault = if (isVoid(env.yieldedType)) {
			macro return;
		} else {
			macro return $e{env.defaultYieldedValue};
		}

		var returnValue = if (isVoid(env.yieldedType)) {
			macro return;
		} else {
			macro return $i{NameController.fieldCurrent()};
		}
		
		var body:Expr = {
			expr: EBlock([
				macro if ($i{NameController.fieldIsConsumed()} && !hasNext()) $returnDefault,
				macro $i{NameController.fieldIsConsumed()} = true,
				returnValue
			]), 
			pos: pos
		};
		
		addMethod(bd, "next", [APublic], [], env.yieldedType, body, pos, iterationMetadata);
		
		// public inline function iterator():Iterator<???>
		
		switch (env.functionKind) {
			case RIterable(t) | RBoth(t) | RUnknown(t):
				
				var body:Expr = {
					expr: EBlock([
						macro return this
					]), 
					pos: pos
				};

				var yieldedType = env.yieldedType != null ? env.yieldedType : macro:StdTypes.Dynamic;
				
				addMethod(bd, "iterator", [APublic, AInline], [], macro:StdTypes.Iterator<$yieldedType>, body, pos, iterationMetadata);
				
			case RIterator(_):
		}
	}
	
	private static function initConstructor (bd:BuildingData, pos:Position): Void {
		
		var body:Expr = { expr: EBlock(bd.constructorBlock), pos: pos };
		addMethod(bd, "new", [APublic], bd.constructorArgs, null, body, pos);
	}
	
	private static function initTypeMetas (bd:BuildingData, pos:Position): Void {
		
		addMeta(bd, ":noDoc", null, pos);
		addMeta(bd, ":final", null, pos);
	}
	
	private static function initTypeParams (bd:BuildingData, env:WorkEnv, pos:Position): Void {
		
		bd.typeDefinition.params = [];
		var ids:Array<String> = [];
		
		function addTypeParameters (params:Array<TypeParameter>): Void {
			
			for (param in params) {
				
				if (ids.indexOf(param.name) != -1) continue;
				
				var p:TypeParamDecl = ExpressionTools.convertToTypeParamDecl(param.t, param.name);
				
				bd.typeDefinition.params.push(p);
				ids.push(p.name);
			}
		}
		
		// Add params from the Class and Function
		
		if (env.classData.isAbstract) {
			addTypeParameters(env.classData.abstractType.params);
		}
		
		addTypeParameters(env.classData.localClass.params);
		
		for (param in env.functionDefinition.params) {
			
			if (ids.indexOf(param.name) != -1) continue;
			
			var p:TypeParamDecl = {
				constraints: param.constraints,
				meta: param.meta,
				name: param.name,
				params: param.params
			};
			
			bd.typeDefinition.params.push(p);
			ids.push(p.name);
		}
	}
	
	private static function initIteratorActions (bd:BuildingData, env:WorkEnv, pos:Position): Void {
		
		for (aGoto in env.gotoActions) {
			
			var lset:Expr = { expr: null, pos: aGoto.e.pos};
			
			env.setActions.push({ e: lset, pos: aGoto.pos + 1 });
			
			var call:Expr = ExpressionTools.makeCall("_" + (aGoto.pos) + "_", [], aGoto.e.pos);
			
			aGoto.e.expr = EBlock([
				lset,
				{ expr: EReturn(call), pos: aGoto.e.pos }
			]);
		}
		
		for (aSetNext in env.setActions) {
			
			aSetNext.e.expr = EBinop(
				Binop.OpAssign, 
				{ expr: EField({ expr: EConst(CIdent("this")), pos: pos }, NameController.fieldCursor()), pos: aSetNext.e.pos },
				{ expr: EConst(CInt( Std.string(aSetNext.pos - 1) )), pos: aSetNext.e.pos }
			);
		}
		
		for (aBreak in env.breakActions) {
			
			aBreak.e.expr = EBlock([
				macro $i{NameController.fieldCompleted()} = true,
				if (isVoid(env.yieldedType)) {
					macro return;
				} else {	
					macro return ${env.defaultYieldedValue}
				}
			]);
		}
	}
	
	private static function initInstanceAccessions (env:WorkEnv): Void {
		
		// Transform instance accessions
		
		for (statement in env.instanceStack) {
			
			switch (statement) {
			case Statement.Accession(_data, _defData):
				
				switch (_data.ident) {
				case IdentRef.IEConst(eRef):
					
					if (_data.names == null) {
						eRef.expr = EField( {expr: EConst(CIdent('this')), pos: eRef.pos}, NameController.fieldInstance() );
					} else {
						var einstance:Expr = {
							expr: EField( {expr: EConst(CIdent('this')), pos: eRef.pos}, NameController.fieldInstance() ),
							pos : eRef.pos
						}
						if(env.classData.isAbstract) {
							// cast the instance as the abstract to access its fields
							var ct:ComplexType = TPath({
								name: env.classData.abstractType.name,
								sub: null,
								pack: env.classData.abstractType.pack,
								params: env.classData.abstractType.params.map(function(tp) return TPType(Context.toComplexType(tp.t))),
							});
							einstance.expr = ECheckType(macro @:pos(einstance.pos) cast ${{ expr: einstance.expr, pos: einstance.pos }}, ct);
						}
						eRef.expr = EField(einstance, _data.names[0]);
					}
					
				default: throw "irrelevant ident reference : " + _data.ident;
				}
				
			default: throw "irrelevant statement : " + statement;
			}
		}
	}
	
	private static function initParentAccessions (env:WorkEnv): Void {
		
		// Transform parent accessions
		
		for (statement in env.parentStack) {
			
			switch (statement) {
			case Statement.Accession(_data, _defData):
				
				if (_data.options.indexOf(IdentOption.KeepAsVar) == -1) {
					
					var parentFieldName:String = NameController.fieldParent(env, _defData.env);
					
					switch (_data.ident) {
						case IdentRef.IEConst(eRef):
							
							if (_data.names[0] == null) {
								eRef.expr = EField( {expr: EConst(CIdent('this')), pos: eRef.pos}, parentFieldName );
							} else {
								var fieldName:String = NameController.localVar(_data.names[0], _defData.scope, _defData.channel, _defData.env.getParentCount() + 1);
								var lfield:Expr = {
									expr: EField({
										expr: EField( {expr: EConst(CIdent('this')), pos: eRef.pos}, parentFieldName ),
										pos : eRef.pos
									}, fieldName ),
									pos: eRef.pos
								};
								eRef.expr = lfield.expr;
							}
							
						default: throw "irrelevant ident reference : " + _data.ident;
					}
					
				} else {
					
					var parentFieldName:String = NameController.parentVar(_data.names[0], _data.scope, _data.channel, _defData.env.getParentCount());
					
					// rename accession
					
					switch (_data.ident) {
						case IdentRef.IEConst(eRef):
							eRef.expr = EConst(CIdent(parentFieldName));
						default: throw "irrelevant ident reference : " + _data.ident;
					}
				}
				
			default:				
			}
		}
	}
	
	private static function initVariableFields (bd:BuildingData, env:WorkEnv): Void {
		
		// Prepare ident channels
		
		var newNameChannels:Map<IdentChannel, Map<UInt, Map<String, String>>> = new Map<IdentChannel, Map<UInt, Map<String, String>>>();
		var nameCounterChannels:Map<IdentChannel, Map<UInt, Map<String, UInt>>> = new Map<IdentChannel, Map<UInt, Map<String, UInt>>>();
		
		for (ic in IdentChannel.getConstructors()) {
			newNameChannels.set(IdentChannel.createByName(ic), new Map<UInt, Map<String, String>>());
			nameCounterChannels.set(IdentChannel.createByName(ic), new Map<UInt, Map<String, UInt>>());
		}
		
		// Process transformations
		
		var newNames:Map<String, String>;
		var nameCounter:Map<String, UInt>;
		
		for (statement in env.localStack) {
			
			switch (statement) {
				
				case Statement.Accession(_data, _definition):
					
					if (_definition == null) {
						Context.fatalError("Unknown identifier : " + _data.names[0], _data.pos);
					}
					
					var scopeDefenition:Scope;
					
					if (newNameChannels[_data.channel].exists(_definition.scope.id)) {
						scopeDefenition = _definition.scope;
					} else {
						Context.fatalError("Unknown identifier : " + _data.names[0], _data.pos);
					}
					
					newNames	= newNameChannels[_data.channel][scopeDefenition.id];
					nameCounter = nameCounterChannels[_data.channel][scopeDefenition.id];
					
					// Change the accession
					
					switch (_data.ident) {
						
						case IdentRef.IEConst(eRef) | IdentRef.IEField(eRef):
							
							switch (eRef.expr) {
								
								case EConst(_c):
									
									if (_definition.options.indexOf(IdentOption.KeepAsVar) == -1) {
										eRef.expr = EField({ expr: EConst(CIdent("this")), pos: eRef.pos }, newNames[_data.names[0]]);
									} else {
										eRef.expr = EConst(CIdent(newNames[_data.names[0]]));
									}
									
								case EField(_e, _field):
									
									eRef.expr = EField(_e, newNames[_data.names[0]]);
									
								default: throw "accession not supported : " + eRef.expr;
							}
							
						default: throw "irrelevant ident reference : " + _data.ident;
					}
					
				case Statement.Definitions(_data, _inlined):
					
					if (!newNameChannels[_data.channel].exists(_data.scope.id)) {
						newNameChannels[_data.channel].set( _data.scope.id, new Map<String, String>() );
						nameCounterChannels[_data.channel].set( _data.scope.id, new Map<String, UInt>() );
					}
					
					newNames	= newNameChannels[_data.channel][_data.scope.id];
					nameCounter = nameCounterChannels[_data.channel][_data.scope.id];
					
					if (_data.names[0] == null) continue;
					
					// Define the new identifier
					
					var counter:UInt;
					for (i in 0..._data.names.length) {
						
						if (!nameCounter.exists(_data.names[i])) counter = 0;
						else counter = nameCounter[_data.names[i]];
						
						var newNameRc:String;
						do {
							newNameRc = NameController.localVar(_data.names[i], _data.scope, _data.channel, ++counter);
						} while (env.getIdentCategoryOf(newNameRc, _data.channel) != IdentCategory.Unknown);
						
						nameCounter.set( _data.names[i], counter );
						newNames.set( _data.names[i], newNameRc );
					}
					
					// Change the declaration
					
					switch (_data.ident) {
						
						case IdentRef.IEVars(eRef): switch (eRef.expr) {
							case EVars(_vars):
								
								var varCount:Int = _vars.length;
								
								for (i in 0...varCount) {
									
									var __var = _vars[i];
									
									if (__var.name == _data.names[i]) {
										
										__var.name = newNames[_data.names[i]];
										
										// add local variable as field
										
										if (_data.options.indexOf(IdentOption.KeepAsVar) == -1) {
											
											var lfieldDecl:Field;
											
											if (WorkEnv.isDynamicTarget())
												if (__var.type == null)
													lfieldDecl = FieldTools.makeFieldFromVar(__var, [APublic], {expr:EConst(CIdent("null")), pos: eRef.pos}, eRef.pos);
												else 
													lfieldDecl = FieldTools.makeFieldFromVar(__var, [APublic], null, eRef.pos);
											else
												lfieldDecl = FieldTools.makeFieldFromVar(__var, [APublic], null, eRef.pos);
											
											lfieldDecl.name = newNames[_data.names[i]];
											bd.typeDefinition.fields.push( lfieldDecl );
										}
									}
								}
								
								// transform var declaration into field assignment
								
								if (_data.options.indexOf(IdentOption.KeepAsVar) == -1) {
									
									var assignations:Array<Expr> = [];
									
									var i:Int = varCount;
									while (--i != -1) {
										
										if (_vars[i].expr != null)
											assignations.push( FieldTools.makeFieldAssignation(newNames[_data.names[i]], _vars[i].expr) );
										else
											_vars.splice(i, 1);
									}
									
									if (assignations.length == 1) 
										eRef.expr = assignations[0].expr;
									else 
										eRef.expr = EBlock(assignations);
									
								}
								
							default:
						}
						case IdentRef.IEFunction(eRef): switch (eRef.expr) {
							case EFunction(_name, _f):
								
								if (_data.options.indexOf(IdentOption.KeepAsVar) == -1) {
									
									// add local function as field
									var lfieldDecl:Field;
									
									if (_inlined) {
										
										lfieldDecl = FieldTools.makeFunctionField(newNames[_data.names[0]], [APublic, AInline], _f, eRef.pos);
										
									} else {

										lfieldDecl = FieldTools.makeFunctionField(newNames[_data.names[0]], [APublic], _f, eRef.pos);

										// transform function declaration into field assignment
										eRef.expr = EConst(CIdent(newNames[_data.names[0]]));
										
									}
									
									bd.typeDefinition.fields.push( lfieldDecl );
									
								} else {

									var name:String = newNames[_data.names[0]];

									eRef.expr = EFunction(#if (haxe_ver >= 4.000) FNamed(name, _inlined) #else name #end, _f);
									
								}
								
							default:
						}
						case IdentRef.IEConst(eRef): switch (eRef.expr) {
							case EConst(_c):
								eRef.expr = EConst(CIdent(newNames[_data.names[0]]));
								
							default:
						}
						
						case IdentRef.ICatch(cRef):
							cRef.name = newNames[_data.names[0]];
							
						case IdentRef.IArg(aRef, pos):
							aRef.name = newNames[_data.names[0]];
							
						default: throw "irrelevant ident reference : " + _data.ident;
					}
					
				case _:
			}
			
		}
	}
	
	private static function initIterativeFunctions (bd:BuildingData, env:WorkEnv, ibd:IteratorBlockData): Void {

		function positionMapping(e:Expr, prevLine = -1):Expr {
			var line = #if (haxe_ver >= 4.000) e.pos.toLocation().range.start.line #else 0 #end;
			var e = switch e.expr {

				// Skipped expressions
				case EBinop(op = OpAssign | OpAssignOp(_),e1,e2): // skip declaration
					return { expr: EBinop(op,e1,positionMapping(e2,prevLine)), pos: e.pos }
				case EFor(it = { expr: EBinop(OpIn,e1,e2) }, e3): // skip capture variable
					e2.expr = positionMapping(e2,prevLine).expr;
					e3.expr = positionMapping(e3,prevLine).expr;
					return e;
				case EArrayDecl(values):
					return e;
				case ESwitch(e1,cases,edef): // skip case's values
					e1.expr = positionMapping(e1,prevLine).expr;
					for(c in cases) {
						if(c.expr != null)
							c.expr.expr = positionMapping(c.expr,prevLine).expr;
						if(c.guard != null)
							c.guard.expr = positionMapping(c.guard,prevLine).expr;
					}
					if(edef != null)
						edef.expr = positionMapping(edef,prevLine).expr;
					return e;
				case EFunction(name,f): // skip arg initialisation
					if(f.expr != null)
						f.expr = positionMapping(f.expr,line);
					e;

				// Maybe throwing expressions
				case EField(_,_):
					e;
				case ECall(_,_) | EThrow(_) | ECast(_,_) | EBinop(_,_,_) | EUnop(_,_):
					ExprTools.map(e, positionMapping.bind(_,line));

				// Loop
				case _:
					return ExprTools.map(e, positionMapping.bind(_,prevLine));
			}
			var mapping = #if (haxe_ver < 4.000)
				macro this._line_ = @:pos(e.pos) (function(?p:haxe.PosInfos) return p.lineNumber)()
			#else if (line != prevLine)
					macro this._line_ = $v{line}
				else
					null
			#end;
			return mapping == null ? e : macro @:pos(e.pos) @:mergeBlock {
				$mapping;
				${{ expr: e.expr, pos: e.pos }};
			};
		}

		if (env.positionMapping) {
			addProperty(bd, "_line_", [APrivate], macro:Int, bd.typeDefinition.pos);
		}
		
		for (i in 0...ibd.length) {
			
			var lExpressions:Array<Expr> = ibd[i];
			var pos = lExpressions[0].pos;
			var exprs = { expr: EBlock(lExpressions), pos: pos };
			var body:Expr = env.positionMapping ? positionMapping(exprs) : exprs;
			
			addMethod(bd, NameController.iterativeFunction(i), [APrivate], [], env.yieldedType, body, pos, env.classField.meta.copy());
		}
	}
	
	private static function initInstanceFunctionBody (bd:BuildingData, pos:Position): Void {
		
		var enew:Expr = {
			expr: ENew(bd.typePath, bd.givenArguments),
			pos:  pos
		};
		
		bd.instanceFunctionBody = {
			expr: EBlock([macro return cast $enew]),
			pos:  pos
		};
	}
	
	static function getTypePath (?c:Type, ?ct:ClassType, isAbstract:Bool = false, abstractType:AbstractType = null): String {
		
		var classPackage:String = "";
		
		var pack:Array<String>;
		var name:String;
		var sub:Null<String> = null;
		
		if (c == null && ct != null) {
			
			pack = isAbstract ? abstractType.pack : ct.pack;
			name = isAbstract ? abstractType.name : ct.name;
			
		} else switch (TypeTools.toComplexType(c)) {
			case TPath(tp):
				
				if (isAbstract) {
					pack = abstractType.pack;
					name = abstractType.name;
				} else {
					pack = tp.pack;
					name = tp.name;
				}
				
				sub = tp.sub;
				
			default:
				throw "type not supported : " + ComplexTypeTools.toString(TypeTools.toComplexType(c));
		}
		
		if (pack.length != 0) classPackage += pack.join(".") + ".";
		
		if (sub != null) {
			classPackage += name + "." + sub;
		} else {
			classPackage += name;
		}
		
		return classPackage;
	}
	
	private static function allowAccessToPrivateFields (env:WorkEnv, pos:Position): Void {
		
		if (env.classData.localComplexType != null) {
			
			function setAccess (c:ClassType) {
				
				env.generatedIteratorClass.meta.push({
					name : ":access",
					params : [Context.parse(getTypePath(c, env.classData.isAbstract, env.classData.abstractType), pos)],
					pos : pos
				});
				if (c.superClass != null) setAccess(c.superClass.t.get());
			}
			
			setAccess(env.classData.localClass);
			
			if (env.classData.isAbstract) {
				
				env.generatedIteratorClass.meta.push({
					name : ":access",
					params : [Context.parse(getTypePath(env.classData.abstractType.type), pos)],
					pos : pos
				});
			}
		}
	}
	
}
#end