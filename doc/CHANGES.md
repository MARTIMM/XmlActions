<!--
* 0.4.7 2020-07-08
  * Added the possibility to process html files which are parsed by **HTML::Parser::XML**.
-->
* 0.5.0 2023-02-15
  * Remove deprecated methods. I recently found a problem regarding readable attributes whithin an `XML::Actions::Work`. It is useful to store data there when an action method has found something and wants to store it there. Raku automatically generates methods to read the attribute. The problem is that when this attribute has the name of a xml node, it will be called with the wrong arguments.

* 0.4.6 2019-10-22
  * XML::Actions::Stream::XmlNode Grammar bugfix; Attribute values may have empty strings

* 0.4.5 2019-10-20
  * Modified grammar for XML::Actions::Stream to improve speed a bit.

* 0.4.4 2019-10-20
  * Removed calls to `someElement:startend()` from XML::Actions::Stream to improve speed a bit.

* 0.4.3 2019-10-19
  * Some changes in XML::Actions::Stream to get the speed somewhat higher

* 0.4.2 2019-10-01
  * A named attribute :startend is added to `someElement:start()` in class XML::Actions::Stream. This might be easier to process than using a separate method `someElement:startend()`. It is a `Bool` which, when `True`, it encountered an element like **<someElement ... />** instead of **<someElement ... > ... </someElement>**.

  * Removed some tests from XML::Actions::Stream to make processing quicker. Assumed is that large files generated elsewhere, are proper XML.
* 0.4.1 2019-10-01
  * PR added from Xliff to read XML from string.
* 0.4.0 2019-09-19
  * Add a module XML::Actions::Stream to process XML data while reading. It does not build a DOM tree like XML::Actions does.
* 0.3.3 2019-09-16
  * Add a deprecation message for methods named after their elements. New methods should be called element-START() as is done for element-END(). Old method call will be removed after version 0.5.0.
  * Bugfix: methods to process text, cdata, text and comments were tested for lowercase names. This must be in uppercase.
* 0.3.2 2019-01-11
  * Added method result() to return serialized xml. It is possible to change xml when processing.
* 0.3.1 2019-01-06
  * <some element>-END() have the same arguments as the element methods have.
  * Improvement of documents and tests.
* 0.3.0 2019-01-02
  * Nodes can be revisited after processing child elements. The method called will be <some element>-END().
* 0.2.0 2019-01-01
  * Added other node types to be processed. Methods are PROCESS-TEXT, PROCESS-COMMENT, PROCESS-CDATA and PROCESS-PI
* 0.1.0 2019-12-21
  * XML file loaded and several checks are in place
  * All XML::Element nodes are walked recursively
  * All Element node names are checked against a method with the same name in a user provided object of type XML::Actions::Work.
  * The method is called with an array of parent elements with their own at the last position. Also attributes from the element are provided.
* 0.0.1 2018-12-20
  * Setup project
