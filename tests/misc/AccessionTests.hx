package misc;


import misc.packs.Parent;
import yield.Yield;

class AccessionTests extends misc.packs.Parent implements Yield
{

	public function new() 
	{
		super();
	}
	
	function testStaticVar () {
		var it = staticVar();
		staticVarField = false;
		assertTrue(it.hasNext());
		assertFalse(staticVarField);
		assertEquals(0, it.next());
		assertFalse(staticVarField);
		assertFalse(it.hasNext());
		assertTrue(staticVarField);
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
		assertTrue(it.hasNext());
		assertFalse(Parent.privateStatic);
		assertFalse(Parent.publicStatic);
		assertEquals(0, it.next());
		assertFalse(Parent.privateStatic);
		assertFalse(Parent.publicStatic);
		assertFalse(it.hasNext());
		assertTrue(Parent.privateStatic);
		assertTrue(Parent.publicStatic);
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
		
		assertEquals(-4, it.next());
		assertEquals(-4, it.next());
		assertEquals(-8, it.next());
		assertEquals(member, -8);
		
		assertEquals(-8, it.next());
		assertEquals(10, it.next());
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
		assertTrue(it.hasNext());
		assertFalse(privateMember);
		assertFalse(publicMember);
		assertEquals(0, it.next());
		assertFalse(privateMember);
		assertFalse(publicMember);
		assertFalse(it.hasNext());
		assertTrue(privateMember);
		assertTrue(publicMember);
	}
	
	function parentMember () {
		@yield return 0;
		privateMember = true;
		publicMember  = true;
	}
	
	function testNestedAccess () {
		
		this.member = 20;
		
		var it:Iterator<Dynamic> = cast nestedAccess();
		
		assertEquals(3, it.next());
		assertEquals(3, it.next());
		assertEquals(12, it.next());
		assertEquals(2, it.next());
		assertEquals(member, 20);
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
	function testAbstractAccessions () {
		var a = new MyAbstract();
		assertTrue(a.test());
	}
	#end
	
}

#if (!cs && !java) // error: repeated modifier
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