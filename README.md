yield
=======
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md)
[![TravisCI Build Status](https://travis-ci.org/dpomier/haxe-yield.svg?branch=master)](https://travis-ci.org/dpomier/haxe-yield)

*Supports Haxe `3.4.7` and `4.0.0-rc.4`*

This library adds the `yield` metadata, which is similar to the `yield` keyword in C#.

The `yield` metadata defines iterator blocks and indicates that the function, operator (see [operator overloading](https://haxe.org/manual/types-abstract-operator-overloading.html)), or accessor in which it appears is an iterator.

When defining an iterator with `yield` statements, an extra class is implicitly created to hold the state for an iteration likewise implementing the [Iterator&lt;T&gt;](http://api.haxe.org/Iterator.html) or [Iterable&lt;T&gt;](http://api.haxe.org/Iterable.html) pattern for a custom type (see [iterators](https://haxe.org/manual/lf-iterators.html) for an example).

Usage
-----

Any `@yield` expressions are available for classes that are annotated with the `:yield` metadata, or available for all classes that extend classes annotated with `:yield(Extend)`.
```haxe
@:yield
class MyClass {
    // ...
}
```

The following example shows the two forms of the `yield` metadata:
```haxe
@yield return expression;
@yield break;
```

Use `@yield return` to return each element one at a time.<br/>
Use `@yield break` to end the iteration.

Iterator methods can be run through using a `for` expression or [Lambda](https://haxe.org/manual/std-Lambda.html) functions. When `@yield return` is reached in the iterator method, `expression` is returned. Execution is restarted from that location the next time that the iterator function is called.

The return type must be [Iterator&lt;T&gt;](http://api.haxe.org/Iterator.html) or [Iterable&lt;T&gt;](http://api.haxe.org/Iterable.html). If no return type is defined, the type will be [Dynamic](https://haxe.org/manual/types-dynamic.html), and can be unified to both Iterator or Iterable.

Exemple
-----

Here’s an example of the `yield` metadata usage:
```haxe
@:yield
class Test {
    function sayHello (name:String):Iterator<String> {
        @yield return “Hello”;
        @yield return name + “!”;
    }
}
```

Here the sayHello function usage:
	
```haxe
for (word in sayHello(“World”)) {
    trace(word); // “Hello”, “World!”
}
```

Call the sayHello method returns an Iterator&lt;String&gt;. The body of the method is not executed yet. 
<br/>The `for` loop iterates over the iterator while the `Iterator<String>.hasNext` method returns true. 
<br/>The method `Iterator<String>.hasNext` executes only once the body of sayHello until the next `@yield` expression is reached. 
In case of a `@yield return`, `Iterator<String>.hasNext` will return true, and the result of the execution can be get once by calling `Iterator<String>.next`.

The `Iterator<String>.next` method can also be used without calling `Iterator<String>.hasNext`. If the end of sayHello is reached, `Iterator<String>.next` returns the default value of the return type.

Here’s a second example:
```haxe
function getCounter ():Iterator<UInt> {
    var i:UInt = 0;
    while (true) {
        @yield return i++;
    }
}

var counter:Iterator<UInt> = getCounter();

counter.next(); // 0
counter.next(); // 1
counter.next(); // 2
// ...
counter.next(); // n
```

Advanced usage
-----

You can compile with some haxe compilation parameters (or pass several `yield.YieldOption` into the `:yield` metadata):

 - `yield-extend`
		If the option is enabled, all extending classes will be able to use `@yield` expressions. If this option affects an interface, all implementing classes and all extending interfaces will be able to use `@yield` expressions. This is disabled by default.
		Compile with `-D yield-extend`.
 - `yield-explicit`
		If the option is enabled, the return type of iterative functions needs to be explicitly specified. This is disabled by default.
		Compile with `-D yield-explicit`.
 - `yield-keyword`
		Use a custom keyword instead of "yield".
		Compile with `-D yield-keyword=myCustomMetaName`.
 - `yield-parse`
		Specifies packages or classpaths to include in the yield parser. All the impacted classes will no longer need to be annotated with `:yield` to be able to use the `@yield` expressions. This can be recursive using the `*` wildcard.
		Compile with `-D yield-parse= my.package.one, my.packages.*, my.class.Foo`.

Install
-----

To install the library, use `haxelib install yield` and compile your program with `-lib yield`.

Development Builds
-----

1. To clone the github repository, use `git clone https://github.com/dpomier/haxe-yield`

2. To tell haxelib where your development copy is installed, use `haxelib dev yield my/repositories/haxe-yield`

To return to release builds use `haxelib dev yield`

To help to debug a specific function, you can use the haxe compilation parameter `-D yield-debug= myFunctionName` to see the result after the parsing is done.

Alternatives
-----

Other libraries addressing generators:

* https://github.com/RealyUniqueName/Coro - Haxe compiler plugin which adds generic coroutines implementation (including built-in async/await and generators)
* https://lib.haxe.org/p/tink_await/ - Adds async/await for [tink_core](https://github.com/haxetink/tink_core) futures
* https://lib.haxe.org/p/moon-core/ - Utility library which includes generator functions, fibers, yield and await

