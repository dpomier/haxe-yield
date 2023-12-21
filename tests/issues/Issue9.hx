package issues;
import utest.*;

class Issue9 extends Test {

	public var array = [1,2,3];
	
	function testIssue5 () {
		new A(this);
	}

}

@:yield
class A {
	
	private var external:Issue9;

	public function new(v) {
		external = v;
		iterator().next();
		Assert.pass();
	}
	 
	function iterator() : Iterator<Dynamic>
	{
		for (i in external.array) {}
	
		@yield break;
	}
}