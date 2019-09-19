# Issue 1

## Changes because of issue #1

* First idea: `method element-START ( Array $parent-path, *%attributes ) { }` like the method to process the end tag `method element-END (...) {...}`

* After experimenting with [extended identifiers](https://docs.perl6.org/syntax/identifiers#Extended_identifiers) I came up with
  * `element:start()`
  * `element:end()`
  These routine names are much nicer to read and namespace names do not interfere.

Extending this idea the following could also change
  * `PROCESS-TEXT` becomes `xml:text()`
  * `PROCESS-COMMENT` becomes `xml:comment()`
  * `PROCESS-CDATA` becomes `xml:cdata()`
  * `PROCESS-PI` becomes `xml:pi()`

The name 'xml' will not interfere with other elements because it is a reserved name.


## REPL Tests
Some tests gave more ideas
```
sub a:<a b>:s (Int $i) {note "\$i = $i"}
&a:<a b>:s

> my @l = <a b>
[a b]

> a:[<a b>]:s (10)
$i = 10
True

> a:[@l]:s (10)
$i = 10
True
```

When you want to find an element with some fixed list of parents;
  * `element:<parent-element-list>:start`
  * `element:<parent-element-list>:end`

And
  * `xml:<parent-element-list>:text()`
  * `xml:<parent-element-list>:comment()`
  * `xml:<parent-element-list>:cdata()`
  * `xml:<parent-element-list>:pi()`


So given an XML like
```
  <html>
    <body>
      <h1>Test for text</h1>
      <p><!-- Test for comment in p -->
        Added text
      </p>
      <![CDATA[ Test for CDATA]]>
      <?PITarget Test for PI?>
    </body>
  </html>
```

Methods like the following could then be declared
* `body:start()`
* `h1:<body html>:end()`
* `xml:<body>:text()`

Perhaps we can get wilder by
* `xml:<html * p>:text()`


# Streaming
Large files cannot be processed because memory will be filled to the rim. Another way of processing must be found which involves reading the xml line by line. This is crystallized in XML::Actions::Stream.
