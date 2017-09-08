package;
import haxe.unit.TestRunner;
import misc.InferenceTests;
import misc.AccessionTests;
import eparsers.ESwitchTests;
import misc.ImportTests;
import misc.IterationTests;
import misc.AbstractTests;
import misc.ScopeTests;
import misc.UsingTests;
import misc.YieldTests;
import eparsers.EForTests;
import eparsers.EFunctionTests;
import eparsers.ETryTests;
import eparsers.EWhileTests;
import eparsers.EIfTests;

class Tests
{
	
	static function main () {
		
		var r:TestRunner = new TestRunner();
		
		// parsers
		r.add(new EIfTests());
		r.add(new EWhileTests());
		r.add(new EForTests());
		r.add(new ETryTests());
		r.add(new EFunctionTests());
		r.add(new ESwitchTests());
		
		// general tests
		r.add(new ScopeTests());
		r.add(new ImportTests());
		r.add(new UsingTests());
		r.add(new YieldTests());
		r.add(new IterationTests());
		r.add(new AbstractTests());
		r.add(new AccessionTests());
		r.add(new InferenceTests());
		
		var success:Bool = r.run();
		
		#if travix
			travix.Logger.exit(success ? 0 : 1);
		#elseif interp
			Sys.exit(0);
		#elseif sys
			Sys.getChar(false);
		#end
	}
	
}