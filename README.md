# XML Actions on every node

[![Build Status](https://travis-ci.org/MARTIMM/XmlActions.svg?branch=master)](https://travis-ci.org/MARTIMM/XmlActions) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/6yaqqq9lgbq6nqot?svg=true&branch=master&passingText=Windows%20-%20OK&failingText=Windows%20-%20FAIL&pendingText=Windows%20-%20pending)](https://ci.appveyor.com/project/MARTIMM/XmlActions/branch/master) [![License](http://martimm.github.io/label/License-label.svg)](http://www.perlfoundation.org/artistic_license_2_0)

## Synopsis
```
use Test;
use XML::Actions;

my Str $file = "a.xml";
$file.IO.spurt(Q:q:to/EOXML/);
  <scxml xmlns="http://www.w3.org/2005/07/scxml"
         version="1.0"
         initial="hello">

    <final id="hello">
      <onentry>
        <log expr="'hello world'" />
      </onentry>
    </final>
  </scxml>
  EOXML


class A is XML::Actions::Work {
  method final:start ( Array $parent-path, :$id ) {
    is $id, 'hello', "final called: id = $id";
    is $parent-path[*-1].name, 'final', 'this node is final';
    is $parent-path[*-2].name, 'scxml', 'parent node is scxml';

  method log:start ( Array $parent-path, :$expr ) {
    is $expr, "'hello world'", "log called: expr = $expr";
    is-deeply @$parent-path.map(*.name), <scxml final onentry log>,
              "<scxml final onentry log> found in parent array";
  }
}

my XML::Actions $a .= new(:$file);
isa-ok $a, XML::Actions, 'type ok';
$a.process(:actions(A.new()));

```
Result would be like
```
ok 1 - type ok
ok 2 - final called: id = hello
ok 3 - this node is final
ok 4 - parent node is scxml
ok 5 - log called: expr = 'hello world'
ok 6 - <scxml final onentry log> found in parent array
```

## Documentation

Users who wish to process **XML::Elements** (from the XML package) must provide an instantiated class which inherits from **XML::Actions::Work**. In that class, methods named after the elements can be defined. Those methods must have `:start` or `:end` attached to have them called when `<someElement>` or `</someElement>` is encountered.

```
class A is XML::Actions::Work {

  method someElement:start ( Array $parent-path, %*attrs --> ActionResult )
  method someElement:end ( Array $parent-path, %*attrs )

  method someOtherElement:start ( Array $parent-path, %*attrs --> ActionResult )
  method someOtherElement:end ( Array $parent-path, %*attrs )
}
```
* The `$parent-path` is an array holding the **XML::Elements** of the parent elements with the root on the first position and the current element on the last.
* The `%*attrs` is a Hash of the found attributes on the element.
* The action may return a ActionResult value. When defined and set to `Truncate`, the caller will not recurse further into this element if there were any.


There are also text-, comment-, cdata- and pi-nodes. They can be processed as
```
  method xml:text ( Array $parent-path, Str $text ) {...}
  method xml:comment ( Array $parent-path, Str $comment ) {...}
  method xml:cdata ( Array $parent-path, Str $cdata ) {...}
  method xml:pi ( Array $parent-path, Str $pi-target, Str $pi-content ) {...}
```


## Large files
When you have to process a large file (e.g. an XML file holding POI data of Turkey from osm planet is about 6.2 Gb), one cannot use the **XML::Actions** module because the DOM tree is build in memory. Since version 0.4.0 the package is extended with module **XML::Actions::Stream** which eats the file in chunks of 128 Kb and chops it up into parseble parts. There will be no check on proper XML because it will slow down too much. You can use other tools for that. There are a few more methods possible to be defined by the user. The arguments to the methods are the same but the first argument, which is an array, has other type of elements.

### User definable  methods
The user can define the methods in a class which inherits from **XML::Actions::Stream::Work**. The methods which the user may define are;

* `xml:prolog ( *%prolog-attributes )`. Found only at the start of a document. It might have attributes `version`, `encoding` and/or `standalone`.
* `xml:doctype ( *%doctype-attributes )`. Alsp found only at the start of document. It might have an internal or external DTD. The arguments can be: `Str :$dtd`, `Str :$url`, `Bool :$empty`, `Bool: $public`, `Bool: $system`, `Str :$fpi`. \$empty is True when there is no DTD, SYSTEM or PUBLIC defined. \$fpi (Formal Public Identifier) should be defined when \$public is True. \$url should be defined when \$system is True but doesn't have to be defined if \$public is True.

* `xml:pi ( Str $target, Str $program )`. For `<?target program?>`.
* `xml:comment ( Str $comment-text )`. For `<!-- comment text -->`.
* `xml:cdata ( Str $data )`. For `<[CDATA[ data ]]>`.
* `xml:text ( Str $text )`. All text as content of an element.

* `someElement:start ( Array $parent-path, Bool :$startend, *%element-attributes )`. The named argument `:startend` is a boolean; when `True`, there is no content in this element.

* `someElement:end ( Array $parent-path, *%element-attributes )`

The array is a list of pairs. The key of each pair is the element name and the value is a hash of its attributes. Entry `$parent-path[*-1]` is the currently called element, so its parent is at `*-2`. The root element is at 0 and is always available.

### Changes
One can find the changes document [in ./doc/CHANGES.md][release]

## Installing
Use zef to install the package: `zef install XML::Actions`

## AUTHORS
Current maintainer **Marcel Timmerman** (MARTIMM on github)

## License
**Artistic-2.0**

<!---- [refs] ----------------------------------------------------------------->
[release]: https://github.com/MARTIMM/XmlActions/blob/master/doc/CHANGES.md
