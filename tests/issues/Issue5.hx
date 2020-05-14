package issues;
import utest.*;

@:yield
class Issue5 extends Test {
	
	function testIssue5 () {
		var it = iterator();
		Assert.pass();
	}
	
	function iterator ():Iterator<Dynamic> {
		
		#if (haxe_ver >= 4.100)
		try Math.random() catch (e) {}
		#end

		@yield break;

	}

}