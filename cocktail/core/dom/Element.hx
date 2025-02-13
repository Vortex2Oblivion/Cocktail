/*
 * Cocktail, HTML rendering engine
 * http://haxe.org/com/libs/cocktail
 *
 * Copyright (c) Silex Labs
 * Cocktail is available under the MIT license
 * http://www.silexlabs.org/labs/cocktail-licensing/
*/
package cocktail.core.dom;

import cocktail.core.html.HTMLConstants;
import cocktail.core.html.HTMLElement;

/**
 * The Element interface represents an element in an HTML or XML document.
 * Elements may have attributes associated with them; since the Element interface 
 * inherits from Node, the generic Node interface attribute attributes may be used
 * to retrieve the set of all attributes for an element. There are methods on the
 * Element interface to retrieve either an Attr object by name or an attribute
 * value by name. In XML, where an attribute value may contain entity references,
 * an Attr object should be retrieved to examine the possibly fairly complex sub-tree
 * representing the attribute value. On the other hand, in HTML, where all attributes 
 * have simple string values, methods to directly access an attribute value can
 * safely be used as a convenience.
 * 
 * @author Yannick DOMINGUEZ
 */
class Element extends Node
{	
	/**
	 * The name of the element
	 */
	public var tagName(default, null):String;
	
	/**
	 * returns a reference to the first child node of that element which is of nodeType Element.
	 * returns, null if this Element has no child nodes or no Element child nodes
	 */
	public var firstElementChild(get, never):Element;
	
	/**
	 * returns a reference to the first last child node of that element which is of nodeType Element.
	 * returns, null if this Element has no child nodes or no Element child nodes
	 */
	public var lastElementChild(get, never):Element;
	
	/**
	 * returns a reference to the first previous sibling element which is of nodeType Element.
	 * returns, null if this Element has no previous siblings or none of them are Element
	 */
	public var previousElementSibling(get, never):Element;
	
	/**
	 * returns a reference to the first next sibling element which is of nodeType Element.
	 * returns, null if this Element has no next siblings or none of them are Element
	 */
	public var nextElementSibling(get, never):Element;
	
	/**
	 * Returns the number of children of this Element which are 
	 * Element
	 */
	public var childElementCount(get, never):Int;
	
	/**
	 * class constructor. Set the name of the tag,
	 * it can't be changed afterwards.
	 */
	public function new(tagName:String) 
	{
		this.tagName = tagName;
		initAttributes();
		super();
	}
	
	/**
	 * Instantiate
	 * the attribute node map. Element node are the
	 * only type of node which can have any
	 */
	private function initAttributes():Void
	{
		attributes = new NamedNodeMap();
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PUBLIC METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Retrieves an attribute value by name.
	 * 
	 * @param	name The name of the attribute to retrieve.
	 * @return The Attr value as a string, or null
	 * if that attribute does not have a specified or default value.
	 * 
	 * note : the spec defines that the empty string should be returned
	 * instead of null but in pracice most browsers implementations
	 * return null
	 */
	public function getAttribute(name:String):String
	{
		var attribute:Attr = getAttributeNode(name);
		if (attribute != null)
		{
			return attribute.value;
		}
		else
		{
			return null;
		}
	}
	
	/**
	 * Adds a new attribute. If an attribute with that name
	 * is already present in the element,
	 * its value is changed to be that of the value parameter.
	 * This value is a simple string; it is not parsed as it
	 * is being set. So any markup (such as syntax to be
	 * recognized as an entity reference) is treated as
	 * literal text, and needs to be appropriately escaped
	 * by the implementation when it is written out.
	 * In order to assign an attribute value that contains
	 * entity references, the user must create an Attr
	 * node plus any Text and EntityReference nodes,
	 * build the appropriate subtree,
	 * and use setAttributeNode to assign it as the value of an attribute.
	 * 
	 * @param	name The name of the attribute to create or alter.
	 * @param	value Value to set in string form.
	 */
	public function setAttribute(name:String, value:String):Void
	{
		var attribute:Attr = attributes.getNamedItem(name);
		if (attribute == null)
		{
			attribute = new Attr(name);
			attributes.setNamedItem(attribute);
			attribute.ownerElement = cast(this);
		}
		
		attribute.value = value;
	}
	
	/**
	 * Retrieves an attribute node by name.
	 * 
	 * @param	name The name (nodeName) of the
	 * attribute to retrieve.
	 * @return The Attr node with the specified name 
	 * (nodeName) or null if there is no such attribute.
	 */
	public function getAttributeNode(name:String):Attr
	{
		var attribute:Attr = attributes.getNamedItem(name);
		
		if (attribute != null)
		{
			return attribute;
		}
		
		return null;
	}
	
	/**
	 * Adds a new attribute node. If an attribute with that name
	 * (nodeName) is already present in the element, 
	 * it is replaced by the new one. 
	 * Replacing an attribute node by itself has no effect.
	 * 
	 * @param newAttr The Attr node to add to the attribute list.
	 * @return If the newAttr attribute replaces an existing attribute,
	 * the replaced Attr node is returned, otherwise null is returned.
	 */
	public function setAttributeNode(newAttr:Attr):Attr
	{
		newAttr.ownerElement = cast(this);
		return attributes.setNamedItem(newAttr);
	}
	
	/**
	 * Removes an attribute by name. If a default value for the removed
	 * attribute is defined in the DTD, a new attribute
	 * immediately appears with the default value as well 
	 * as the corresponding namespace URI, local name, and prefix 
	 * when applicable. 
	 * If no attribute with this name is found, this method has no effect.
	 * 
	 * @param	name The name of the attribute to remove.
	 */
	public function removeAttribute(name:String):Void
	{
		var removedAttribute:Attr = attributes.removeNamedItem(name);
		
		if (removedAttribute != null)
		{
			removedAttribute.ownerElement = null;
		}
	}
	
	/**
	 * If the parameter isId is true, this method 
	 * declares the specified attribute to be a user-determined 
	 * ID attribute. This affects the value of Attr.isId and
	 * the behavior of Document.getElementById, but does not
	 * change any schema that may be in use, in particular this
	 * does not affect the Attr.schemaTypeInfo of the specified
	 * Attr node. Use the value false for the parameter isId to
	 * undeclare an attribute for being a user-determined ID attribute. 
	 * 
	 * TODO 5 : implement schemaTypeInfo
	 * 
	 * @param	name The name of the attribute.
	 * @param	isId Whether the attribute is a of type ID.
	 */
	public function setIdAttribute(name:String, isId:Bool):Void
	{
		var idAttribute:Attr = attributes.getNamedItem(name);
		if (idAttribute == null)
		{
			idAttribute = new Attr(name);
			attributes.setNamedItem(idAttribute);
			idAttribute.ownerElement = cast(this);
		}
		
		idAttribute.isId = isId;
	}
	
	/**
	 * If the parameter isId is true, this method declares
	 * the specified attribute to be a user-determined 
	 * ID attribute. This affects the value of Attr.isId
	 * and the behavior of Document.getElementById, but does
	 * not change any schema that may be in use, in particular
	 * this does not affect the Attr.schemaTypeInfo of the
	 * specified Attr node. Use the value false for the parameter
	 * isId to undeclare an attribute for being a user-determined
	 * ID attribute. 
	 * 
	 * @param	idAttr The attribute node.
	 * @param	isId Whether the attribute is a of type ID.
	 */
	public function setIdAttributeNode(idAttr:Attr, isId:Bool):Void
	{
		idAttr.isId = isId;
		attributes.setNamedItem(idAttr);
	}
	
	/**
	 * Returns true when an attribute with a given name 
	 * is specified on this element or has a default value, false otherwise.
	 * 
	 * @param	name The name of the attribute to look for.
	 * @return true if an attribute with the given name 
	 * is specified on this element or has a default value, false otherwise.
	 */
	public function hasAttribute(name:String):Bool
	{
		return attributes.getNamedItem(name) != null;
	}
	
	/**
	 * Returns a NodeList of all descendant
	 * Elements with a given tag name, in document order.
	 * 
	 * IMPORTANT : return array of HTMLElement because of haxe JS
	 * 
	 * @param	tagName The name of the tag to match on. The special value "*" matches all tags.
	 * @return	A list of matching Element nodes.
	 */
	public function getElementsByTagName(tagName:String):Array<HTMLElement>
	{
		var elements:Array<HTMLElement> = new Array<HTMLElement>();
		doGetElementsByTagName(cast(this), tagName, elements);
		return elements;
	}
	
	/**
	 * Returns a set of elements which have all the given class names.
	 * 
	 * IMPORTANT : return array of HTMLElement because of haxe JS
	 * 
	 * @param	className the class name to match. If it is a list of class names
	 * separated by spaces, it returns only the elements which matches all the class
	 * names
	 * @return A list of matching Element nodes.
	 */
	public function getElementsByClassName(className:String):Array<HTMLElement>
	{
		var elements:Array<HTMLElement> = new Array<HTMLElement>();
		doGetElementsByClassName(cast(this), className, elements);
		return elements;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Overriden as for element node, attributes
	 * are cloned as well
	 */
	override private function doCloneNode():Element
	{
		var clonedElement:Element = new Element(tagName);
		
		var length:Int = attributes.length;
		for (i in 0...length)
		{
			var clonedAttr:Attr = cast(attributes.item(i).cloneNode(false));
			clonedElement.setAttributeNode(clonedAttr);
		}
		
		return cast(clonedElement);
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PRIVATE METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * do get the matching child elements by 
	 * traversing the DOM tree recursively
	 */
	private function doGetElementsByTagName(node:HTMLElement, tagName:String, elements:Array<HTMLElement>):Void
	{
		if (node.hasChildNodes() == true)
		{
			var length:Int = node.childNodes.length;
			for (i in 0...length)
			{
				var childNode:Node = node.childNodes[i];
				
				//if matching tagName, push child node
				if (childNode.nodeName == tagName)
				{
					elements.push(cast(childNode));
				}
				//else if any tagName is accepted and the child node is an element node, push child node
				else if (tagName == DOMConstants.MATCH_ALL_TAG_NAME && childNode.nodeType == DOMConstants.ELEMENT_NODE)
				{
					elements.push(cast(childNode));
				}
				
				if (childNode.nodeType == DOMConstants.ELEMENT_NODE)
				{
					doGetElementsByTagName(cast(childNode), tagName, elements);
				}
			}
		}
	}
	
	/**
	 * do get the matching child elements by 
	 * traversing the DOM tree recursively
	 */
	private function doGetElementsByClassName(node:HTMLElement, className:String, elements:Array<HTMLElement>):Void
	{
		if (node.hasChildNodes() == true)
		{
			var length:Int = node.childNodes.length;
			for (i in 0...length)
            {
                if (node.childNodes[i].nodeType == DOMConstants.ELEMENT_NODE)
                {
                    var childNode:HTMLElement = cast(node.childNodes[i]);
                    switch (childNode.nodeType)
                    {
                        case DOMConstants.ELEMENT_NODE:
                            var classList:Array<String> = childNode.classList;
                            if (classList != null)
                            {
                                var foundFlag:Bool = false;
                                var classListLength:Int = classList.length;
                                for (j in 0...classListLength)
                                {
                                    if (classList[j] == className && foundFlag == false)
                                    {
                                        elements.push(childNode);
                                        foundFlag = true;
                                    }
                                }
                            }
                    }
                    
                    doGetElementsByClassName(childNode, className, elements);
                }
			}
		}
	}
	
	/**
	 * return the concatenation of the text of all
	 * descendant elements of node
	 */
	private function doGetTextContent(node:Node):String
	{
		var text:String = "";
		
		if (node.hasChildNodes() == true)
		{
			var length:Int = node.childNodes.length;
			for (i in 0...length)
			{
				var childNode:Node = node.childNodes[i];
				switch (childNode.nodeType)
				{
					case DOMConstants.TEXT_NODE:
						var textNode:Text = cast(childNode);
						text += textNode.data;
				}
				
				text += doGetTextContent(childNode);
			}
		}
		
		return text;
	}

	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PUBLIC METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	override public function hasAttributes():Bool
	{
		return attributes.length > 0;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN SETTERS/GETTERS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	override private function get_nodeName():String
	{
		return tagName;
	}
	
	override private function get_nodeType():Int
	{
		return DOMConstants.ELEMENT_NODE;
	}
	
		
	override private function get_textContent():String
	{
		return doGetTextContent(cast(this));
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// ELEMENT TRAVERSAL GETTERS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	private function get_firstElementChild():Element
	{
		if (hasChildNodes() == false)
		{
			return null;
		}
		
		if (firstChild.nodeType == DOMConstants.ELEMENT_NODE)
		{
			return cast(firstChild);
		}
		else
		{
			var length:Int = childNodes.length;
			for (i in 0...length)
			{
				if (childNodes[i].nodeType == DOMConstants.ELEMENT_NODE)
				{
					return cast(childNodes[i]);
				}
			}
		}
		
		return null;
	}
	
	private function get_lastElementChild():Element
	{
		if (hasChildNodes() == false)
		{
			return null;
		}
		
		if (lastChild.nodeType == DOMConstants.ELEMENT_NODE)
		{
			return cast(lastChild);
		}
		else
		{
			var length:Int = childNodes.length;
			for (i in length...0)
			{
				if (childNodes[i].nodeType == DOMConstants.ELEMENT_NODE)
				{
					return cast(childNodes[i]);
				}
			}
		}
		
		return null;
	}
	
	private function get_nextElementSibling():Element
	{
		if (nextSibling == null)
		{
			return null;
		}
		
		var nextElementSibling:Element = cast(nextSibling);
		
		while (nextElementSibling.nodeType != DOMConstants.ELEMENT_NODE)
		{
			nextElementSibling = cast(nextElementSibling.nextSibling);
			
			if (nextElementSibling == null)
			{
				return null;
			}
		}
		
		return nextElementSibling;
	}
	
	private function get_previousElementSibling():Element
	{
		if (previousSibling == null)
		{
			return null;
		}
		
		var previousElementSibling:Element = cast(previousSibling);
		
		while (previousElementSibling.nodeType != DOMConstants.ELEMENT_NODE)
		{
			previousElementSibling = cast(previousElementSibling.previousSibling);
			
			if (previousElementSibling == null)
			{
				return null;
			}
		}
		
		return previousElementSibling;
	}
	
	private function get_childElementCount():Int
	{
		var childElementCount:Int = 0;
		
		var length:Int = childNodes.length;
		for (i in 0...length)
		{
			if (childNodes[i].nodeType == DOMConstants.ELEMENT_NODE)
			{
				childElementCount++;
			}
		}
		
		return childElementCount;
	}
}
