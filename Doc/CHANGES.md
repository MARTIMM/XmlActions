
* 0.2.0
  * Added other node types to be processed. Methods are PROCESS-TEXT, PROCESS-COMMENT, PROCESS-CDATA and PROCESS-PI
* 0.1.0
  * XML file loaded and several checks are in place
  * All XML::Element nodes are walked recursively
  * All Element node names are checked against a method with the same name in a user provided object of type XML::Actions::Work.
  * The method is called with an array of parent elements with their own at the last position. Also attributes from the element are provided.
* 0.0.1 Setup project
