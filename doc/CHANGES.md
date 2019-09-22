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
