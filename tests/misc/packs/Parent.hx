package misc.packs;
import haxe.unit.TestCase;

class Parent extends TestCase {

	public function new () {
		super();
	}
	
	private static var privateStatic:Bool = false;
	public static var publicStatic:Bool = false;
	private var privateMember:Bool = false;
	public var publicMember:Bool = false;
	
}