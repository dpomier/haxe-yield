package issues;
import utest.*;

@:yield
class Issue5 extends Test {
	
	function testIssue5 () {
		var it = iterator();
		Assert.pass();
	}
	
	function iterator ():Iterator<Dynamic> {
		
		try Math.random() catch (e) {}

		@yield break;

	}

}