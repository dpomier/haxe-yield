yield
=======
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md)
[![TravisCI Build Status](https://travis-ci.org/dpomier/haxe-yield.svg?branch=master)](https://travis-ci.org/dpomier/haxe-yield)

*Supports Haxe `3.4.2` and higher (Haxe 4 is not supported for now though, but it is coming soon)*

This library adds the `yield` metadata, which is similar to the `yield` keyword in C#.

The `yield` metadata defines iterator blocks and indicates that the function, operator (see [operator overloading](https://haxe.org/manual/types-abstract-operator-overloading.html)), or accessor in which it appears is an iterator.

When defining an iterator with `yield` statements, an extra class is implicitly created to hold the state for an iteration likewise implementing the [Iterator&lt;T&gt;](http://api.haxe.org/Iterator.html) or [Iterable&lt;T&gt;](http://api.haxe.org/Iterable.html) pattern for a custom type (see [iterators](https://haxe.org/manual/lf-iterators.html) for an example).

Usage
-----

Any `@yield` statements are available for classes that are annotated with the `:yield` metadata, or available for all classes that extend classes annotated with `:yield(Extend)`.
```haxe
@:yield
class MyClass {
    // ...
}
```
When dealing with abstracts, use `@:build(yield.parser.Parser.run())` instead of `@:yield`.

The following example shows the two forms of the `yield` metadata:
```haxe
@yield return expression;
@yield break;
```

Use a `@yield return` statement to return each element one at a time.<br/>
Use a `@yield break` statement to end the iteration.

Iterator methods can be run through using a `for` expression or [Lambda](https://haxe.org/manual/std-Lambda.html) functions. When a `yield return` statement is reached in the iterator method, `expression` is returned. Execution is restarted from that location the next time that the iterator function is called.

The return type must be [Iterator&lt;T&gt;](http://api.haxe.org/Iterator.html) or [Iterable&lt;T&gt;](http://api.haxe.org/Iterable.html). If no return type is defined, the type will be [Dynamic](https://haxe.org/manual/types-dynamic.html), and can be unified to both Iterator or Iterable.

Exemple
-----

Here’s an example of the `yield` metadata usage:
```haxe
function sayHello (name:String):Iterator<String> {
    @yield return “Hello”;
    @yield return name + “!”;
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
<br/>The method `Iterator<String>.hasNext` executes only once the body of sayHello until the next `@yield` statement is reached. 
In case of a `@yield return` statement, `Iterator<String>.hasNext` will return true, and the result of the execution can be get once by calling `Iterator<String>.next`.

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

You can compile with some options or pass several `yield.YieldOption` into the `:yield` metadata.

Available options are:

 - `yieldExtend`
		If the option is enabled, all extending classes will be able to use yield statements. If this option affects an interface, all implementing classes and all extending interfaces will be able to use yield statements. This is disabled by default.
		Compile with `-D yieldExtend`.
 - `yieldExplicit`
		If the option is enabled, the return type of iterative functions needs to be explicitly specified. This is disabled by default.
		Compile with `-D yieldExplicit`.
 - `yieldKeyword`
		Use a custom keyword instead of "yield".
		Compile with `-D yieldKeyword=myCustomMetaName`.

`@yield return` statements can be located in `try` blocks. This will duplicate the `catch` expressions as many times as there are iterator blocks.

Install
-----

To install the library, use `haxelib install yield` and compile your program with `-lib yield`.

