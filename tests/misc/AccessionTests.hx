package misc;

import utest.Assert;
import misc.packs.Parent;

@:yield
class AccessionTests extends misc.packs.Parent {

	public function new() 
	{
		super();
	}
	
	function testStaticVar () {
		var it = staticVar();
		staticVarField = false;
		Assert.isTrue(it.hasNext());
		Assert.isFalse(staticVarField);
		Assert.equals(0, it.next());
		Assert.isFalse(staticVarField);
		Assert.isFalse(it.hasNext());
		Assert.isTrue(staticVarField);
	}
	
	static var staticVarField:Bool = false;
	
	function staticVar () {
		@yield return 0;
		staticVarField = true;
	}
	
	function testParentStaticVar () {
		var it = parentStaticVar();
		Parent.privateStatic = false;
		Parent.publicStatic  = false;
		Assert.isTrue(it.hasNext());
		Assert.isFalse(Parent.privateStatic);
		Assert.isFalse(Parent.publicStatic);
		Assert.equals(0, it.next());
		Assert.isFalse(Parent.privateStatic);
		Assert.isFalse(Parent.publicStatic);
		Assert.isFalse(it.hasNext());
		Assert.isTrue(Parent.privateStatic);
		Assert.isTrue(Parent.publicStatic);
		Parent.reset();
	}
	
	function parentStaticVar () {
		@yield return 0;
		Parent.privateStatic = true;
		Parent.publicStatic  = true;
	}
	
	var member:Int;
	
	function testInstanceAccess () {
		
		this.member = -4;
		
		var it:Iterator<Dynamic> = cast instanceAccess();
		
		Assert.equals(-4, it.next());
		Assert.equals(-4, it.next());
		Assert.equals(-8, it.next());
		Assert.equals(member, -8);
		
		Assert.equals(-8, it.next());
		Assert.equals(10, it.next());
	}
	
	function instanceAccess (): Iterator<Int> {
		
		@yield return this.member;
		@yield return member;
		member = -8;
		@yield return this.member;
		
		var member = 10;
		@yield return this.member;
		@yield return member;
	}
	
	function testParentMember () {
		var it = parentMember();
		privateMember = false;
		publicMember  = false;
		Assert.isTrue(it.hasNext());
		Assert.isFalse(privateMember);
		Assert.isFalse(publicMember);
		Assert.equals(0, it.next());
		Assert.isFalse(privateMember);
		Assert.isFalse(publicMember);
		Assert.isFalse(it.hasNext());
		Assert.isTrue(privateMember);
		Assert.isTrue(publicMember);
	}
	
	function parentMember () {
		@yield return 0;
		privateMember = true;
		publicMember  = true;
	}
	
	function testNestedAccess () {
		
		this.member = 20;
		
		var it:Iterator<Dynamic> = cast nestedAccess();
		
		Assert.equals(3, it.next());
		Assert.equals(3, it.next());
		Assert.equals(12, it.next());
		Assert.equals(2, it.next());
		Assert.equals(member, 20);
	}
	
	function nestedAccess (): Iterator<Int> {
		
		var a = 0;
		
		function b () {
			a = 3;
			@yield return a;
			@yield return a * 2;
			var a = 1;
			@yield return a*2;
			@yield return member;
		}
		
		var bIterator:Iterator<Dynamic> = cast b();
		
		@yield return bIterator.next();
		@yield return a;
		a = 6;
		@yield return bIterator.next();
		@yield return bIterator.next();
		@yield return bIterator.next();
	}
	
	#if (!cs && !java) // error: repeated modifier
	#if !lua // error Lua 5.2.3 / luarocks 2.4.3: attempt to call global '_iterator' (a nil value)
	function testAbstractAccessions () {
		var a = new MyAbstract();
		Assert.isTrue(a.test());
	}
	#end
	#end
	
	#if (interp && haxe_ver < 4.000)
	function testUntyped () {
		var it = untypedFunc();
		Assert.isFalse(it.hasNext());
		
		var it = untypedNestedFunc();
		Assert.isFalse(it.next());
	}

	function untypedFunc () untyped {

		try {
			unknown(); // should compile
		} catch (e:Dynamic) { }

		@yield break;
	}

	function untypedNestedFunc () {

		untyped function subEnv () {

			try {
				unknown(); // should compile
			} catch (e:Dynamic) { }

			@yield break;
		}

		@yield return subEnv().hasNext();
	}

	function testUnknownIdent () {
		var it = unknownIdent();
		Assert.isFalse(it.hasNext());
	}

	function unknownIdent () {

		try {
			untyped unknown(); // should compile
		} catch (e:Dynamic) { }

		untyped try {
			unknown(); // should compile
		} catch (e:Dynamic) { }

		// unknown(); // TODO: test compilation error

		@yield break;
	}
	#end
}

#if (!cs && !java) // error: repeated modifier
#if !lua // error Lua 5.2.3 / luarocks 2.4.3: attempt to call global '_iterator' (a nil value)
@:build(yield.parser.Parser.run())
@:access(misc.packs.Parent)
abstract MyAbstract (Parent) {
	public inline function new() {
		this = new Parent();
	}
	
	public function test (): Bool {
		this.publicMember  = false;
		this.privateMember = false;
		untyped Parent.privateStatic = false;
		Parent.publicStatic  = false;
		
		var it = iterator();
		return
			it.hasNext()
			&& !this.privateMember && !this.publicMember && !Parent.privateStatic && !Parent.publicStatic
			&& it.next() == null
			&& !this.privateMember && !this.publicMember && !Parent.privateStatic && !Parent.publicStatic
			&& !it.hasNext()
			&& this.privateMember && this.publicMember && Parent.privateStatic && Parent.publicStatic;
	}
	
	function iterator () {
		@yield return null;
		this.privateMember = true;
		this.publicMember  = true;
		Parent.privateStatic = true;
		Parent.publicStatic  = true;
	}
}
#end
#end