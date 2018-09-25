package misc.packs;


class Parent extends utest.Test {

	public function new () {
		super();
	}
	
	private static var privateStatic:Bool = false;
	public static var publicStatic:Bool = false;
	private var privateMember:Bool = false;
	public var publicMember:Bool = false;
	
	public static function reset ()
	{
		privateStatic = false;
		publicStatic  = false;
	}
	
	public function resetMembers ()
	{
		privateMember = false;
		publicMember  = false;
	}
	
}