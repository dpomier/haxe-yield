package misc;

import utest.Assert;

@:yield
class ErrorTests extends utest.Test {
	
	#if ((haxe_ver >= 4.100) && (debug && !no_yield_follow_positions || yield_position_mapping))
	function positionMapping (test:Int): Iterator<Any> {

		@yield return 0;

		var s:String = test == 0 ? null : "test-0";
		var v:Int = s.length; // field

		@yield return v;

		var s:String = test == 1 ? null : "test-1";
		var v = s.substr(0, 4); // call

		@yield return v;
	}

	function testFollowPosition () {
		var expectedTestCount = 2;

		function stringContains(best, otherwise, text, ?pos:haxe.PosInfos) {
			if(StringTools.contains(text, best))
				Assert.stringContains(best, text, pos);
			else if(StringTools.contains(text, otherwise))
				Assert.stringContains(otherwise, text, pos);
			else
				Assert.stringContains(best, text, pos);
		}

		var it:Iterator<Any> = cast positionMapping( 0 );
		try while(it.hasNext()) it.next() catch(e) {
			stringContains("misc/ErrorTests.hx:14: ", "misc/ErrorTests.hx:14", Std.string(e.details()));
			expectedTestCount--;
		}

		var it:Iterator<Any> = cast positionMapping( 1 );
		try while(it.hasNext()) it.next() catch(e) {
			stringContains("misc/ErrorTests.hx:19: ", "misc/ErrorTests.hx:19", Std.string(e.details()));
			expectedTestCount--;
		}

		Assert.equals(0, expectedTestCount);
	}
	#end
	
}