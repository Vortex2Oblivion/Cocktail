 /*
	This file is part of Cocktail http://www.silexlabs.org/groups/labs/cocktail/
	This project is © 2010-2011 Silex Labs and is released under the GPL License:
	This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (GPL) as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. 
	This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	To read the license please visit http://www.gnu.org/copyleft/gpl.html
*/
package cocktail.core.renderer;

import cocktail.core.css.CascadeManager;
import cocktail.core.css.CSSStyleDeclaration;
import cocktail.core.css.InitialStyleDeclaration;
import cocktail.core.dom.Node;
import cocktail.core.event.Event;
import cocktail.core.event.UIEvent;
import cocktail.core.event.WheelEvent;
import cocktail.core.geom.GeomUtils;
import cocktail.core.html.HTMLDocument;
import cocktail.core.html.HTMLElement;
import cocktail.core.html.ScrollBar;
import cocktail.core.linebox.LineBox;
import cocktail.core.linebox.InlineBox;
import cocktail.core.css.CoreStyle;
import cocktail.core.layout.floats.FloatsManager;
import cocktail.core.layout.LayoutData;
import cocktail.core.font.FontData;
import cocktail.core.css.CSSData;
import cocktail.core.geom.GeomData;
import cocktail.core.graphics.GraphicsContext;
import cocktail.Lib;
import haxe.Log;
import cocktail.core.layer.LayerRenderer;

/**
 * A block box renderer is an element which participate
 * in a block or inline formatting context and which can establish
 * either a block or inline formatting context.
 * 
 * When it starts an inline formatting context, it holds
 * an array of line box which which represents
 * each line created by this block box.
 * 
 * @author Yannick DOMINGUEZ
 */
class BlockBoxRenderer extends FlowBoxRenderer
{	
	/**
	 * An array where each item represents a line
	 * . Used when this block box establishes an 
	 * inline formatting context
	 */
	public var lineBoxes(default, null):Array<LineBox>;
	
	public var floatsManager:FloatsManager;
	
	private var _isLayingOut:Bool;
	
	/**
	 * during block layout, store position
	 * where next block child will be placed,
	 * relative to containing block (this)
	 */
	private var _childPosition:PointVO;
	
	/**
	 * during inline formatting, store the
	 * position where the next line box
	 * will be placed relative to containing
	 * block (this)
	 */
	private var _lineBoxPosition:PointVO;
	
	/**
	 * Reused structure when computing bounds
	 * of inline children, used to hold
	 * the bounds of an inline box with the added
	 * x and y offset of its line box so that it is
	 * converted to the space of the containing block 
	 * (this)
	 */
	private var _inlineBoxGlobalBounds:RectangleVO;
	
	/**
	 * class constructor.
	 * Init class attributes
	 */
	public function new(node:HTMLElement) 
	{
		super(node);
		
		_lineBoxPosition = new PointVO(0, 0);
		_childPosition = new PointVO(0, 0);
		lineBoxes = new Array<LineBox>();
		floatsManager = new FloatsManager();
		_inlineBoxGlobalBounds = new RectangleVO();
		_isLayingOut = false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PUBLIC METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * If this block element renderer has both inline and
	 * block children, the inline children are wrapped
	 * in anonymous block to preserve the CSS invariant
	 * where all children of a block must either be all
	 * inline or all block
	 */
	override public function updateAnonymousBlock():Void
	{
		//flag determining wether inline children must be wrapped
		//in anonymous block
		var shouldMakeChildrenNonInline:Bool = false;
		
		//the BlockBoxRenderer should have at least one significant child to determine wether to 
		//establish/participate in a block or inline formatting context, and thus if inline children
		//shoud be wrapped in anonymous block
		if (hasSignificantChild() == true)
		{
			//store wether the children of this block are curently inline
			//or block
			var childrenInline:Bool = childrenInline();
			
			//loop in all children, looking for one which doesn't
			//coreespond to the currrent formatting of the block
			var child:ElementRenderer = firstChild;
			while(child != null)
			{
				//absolutely positioned children are not taken into account when determining wether this
				//BlockBoxRenderer establishes/participate in a block or inline formatting context
				if (child.isPositioned() == false || child.isRelativePositioned() ==  true)
				{	
					//if this child doesn't match the display of the other children,
					///for instance if it is the first inline while all the other
					//children are block, all the inline children should be wrapped in 
					//anonymous blocks
					if (child.isInlineLevel() != childrenInline)
					{
						shouldMakeChildrenNonInline = true;
						break;
					}
				}
				
				child = child.nextSibling;
			}
		}
		
		//make all children non inline if necessary
		if (shouldMakeChildrenNonInline == true)
		{
			makeChildrenNonInline();
		}
		
		super.updateAnonymousBlock();
	}
	
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PRIVATE ANONYMOUS BLOCK METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * This method is called when all the inline children of this block
	 * box should be wrapped in anonymous block. It is done to preserve
	 * the invariant in CSS where all the children of a block box must
	 * either all be block or must all be inline. Wrapping inline children
	 * makes all the children blocks
	 */
	private function makeChildrenNonInline():Void
	{
		//will store all the current block children and the newly created
		//anonymous block, in order and will replace the current child nodes array
		var newChildNodes:Array<ElementRenderer> = new Array<ElementRenderer>();
		
		//loop in the child nodes in reverse order, as the child nodes
		//array will be modified during this loop
		var child:ElementRenderer = lastChild;
		while(child != null)
		{
			var previousSibling:ElementRenderer = child.previousSibling;
			
			//for inline children, create an anonymous block, and attach the child to it
			if (child.isInlineLevel() == true)
			{
				//TODO 2 : only 1 anonymous block should be created for contiguous
				//inline elements
				var anonymousBlock:AnonymousBlockBoxRenderer = createAnonymousBlock(child);
				newChildNodes.push(anonymousBlock);
			}
			else
			{
				newChildNodes.push(child);
			}
			
			child = previousSibling;
		}
		
		//must reverse as the child nodes where
		//looped in reverse order
		newChildNodes.reverse();
		
		//attach all the block children and the newly
		//created anonymous block box
		var length:Int = newChildNodes.length;
		for (i in 0...length)
		{
			appendChild(newChildNodes[i]);
		}
	}
	
	/**
	 * create an anonymous block and append an inline child to it
	 */ 
	private function createAnonymousBlock(child:ElementRenderer):AnonymousBlockBoxRenderer
	{
		var anonymousBlock:AnonymousBlockBoxRenderer = new AnonymousBlockBoxRenderer();
		anonymousBlock.appendChild(child);
		
		anonymousBlock.coreStyle = anonymousBlock.domNode.coreStyle;
		
		//TODO 2 : shouldn't have to instantiate each time
		var cascadeManager:CascadeManager = new CascadeManager();
		cascadeManager.shouldCascadeAll();
		
		var initialStyleDeclaration:InitialStyleDeclaration = Lib.document.initialStyleDeclaration;
		
		//only use initial style declarations
		anonymousBlock.coreStyle.cascade(cascadeManager, initialStyleDeclaration,
		initialStyleDeclaration, initialStyleDeclaration, 
		initialStyleDeclaration, 12, 12, false);
		
		return anonymousBlock;
	}
	
	/**
	 * returns wether the FlowBoxRenderer has at least one significant child
	 * which can define wether he establish/participate in a block or inline
	 * formatting context.
	 * 
	 * For instance if the FlowBoxRenderer has only absolutely positioned
	 * or floated children, it can't yet know from its children wether
	 * to establish/participate in a bock or inline formatting context
	 */
	private function hasSignificantChild():Bool
	{
		var child:ElementRenderer = firstChild;
		while(child != null)
		{
			if (child.isFloat() == false)
			{
				if (child.isPositioned() == false || child.isRelativePositioned() == true)
				{
					//if at least one child child is not absolutely positioned
					//or floated, formatting context to used can be determined
					return true;
				}
			}
			
			child = child.nextSibling;
		}
		return false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE RENDERING METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Overriden as a BlockBoxRenderer render its children too
	 */
	override private function renderChildren(graphicContext:GraphicsContext, clipRect:RectangleVO, scrollOffset:PointVO):Void
	{
		super.renderChildren(graphicContext, clipRect, scrollOffset);
		
		//the BlockBoxRenderer is responsible for rendering its children in the same layer
		//context if it establishes a layer itself or is rendered as if it did
		if (createOwnLayer() == true || rendersAsIfCreateOwnLayer() == true)
		{
			//render all the block box which belong to the same stacking context
			renderBlockContainerChildren(this, layerRenderer, graphicContext, clipRect, scrollOffset);
			
			//TODO 5 : render non-positioned float
			
			//render all the replaced (embedded) box displayed as blocks belonging
			//to the same stacking context
			renderBlockReplacedChildren(this, layerRenderer, graphicContext, clipRect, scrollOffset);
			
			//render all the line boxes belonging to the same stacking context
			renderLineBoxes(this, layerRenderer, graphicContext, clipRect, scrollOffset);
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PRIVATE RENDERING METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Render all the LineBoxes of child BlockBoxRenderer which
	 * belong to the same stacking context as this BlockBoxRenderer
	 */
	private function renderLineBoxes(rootRenderer:ElementRenderer, referenceLayer:LayerRenderer, graphicContext:GraphicsContext, clipRect:RectangleVO, scrollOffset:PointVO):Void
	{
		if (rootRenderer.isBlockContainer() == true && rootRenderer.childrenInline() == true)
		{	
			renderInlineChildren(rootRenderer, referenceLayer, graphicContext, clipRect, scrollOffset);
		}
		else
		{
			var child:ElementRenderer = rootRenderer.firstChild;
			while(child != null)
			{
				if (child.layerRenderer == referenceLayer)
				{
					if (child.isReplaced() == false)
					{	
						renderLineBoxes(child, referenceLayer, graphicContext, clipRect, scrollOffset);
					}
				}
				
				child = child.nextSibling;
			}
		}
	}
	
	private function renderInlineChildren(rootRenderer:ElementRenderer, referenceLayer:LayerRenderer, graphicContext:GraphicsContext, clipRect:RectangleVO, scrollOffset:PointVO):Void
	{
		var child:ElementRenderer = rootRenderer.firstChild;
		while(child != null)
		{
			if (child.layerRenderer == referenceLayer)
			{
				child.render(graphicContext, clipRect, scrollOffset);
				
				//TODO : should ne render float, other condition too ? inline-block ?
				if (child.firstChild != null)
				{
					renderInlineChildren(child, referenceLayer, graphicContext, clipRect, scrollOffset);
				}
			}
			
			child = child.nextSibling;
		}
	}
	
	/**
	 * Render all the replaced children displayed as blocks which
	 * belong to the same stacking context as this BlockBoxRenderer
	 */
	private function renderBlockReplacedChildren(rootRenderer:ElementRenderer, referenceLayer:LayerRenderer, graphicContext:GraphicsContext, clipRect:RectangleVO, scrollOffset:PointVO):Void
	{
		var child:ElementRenderer = rootRenderer.firstChild;
		while(child != null)
		{
			if (child.layerRenderer == referenceLayer)
			{
				//TODO 2 : must add more condition, for instance, no float
				if (child.isReplaced() == false && child.coreStyle.getKeyword(child.coreStyle.display) == CSSKeywordValue.BLOCK )
				{
					renderBlockReplacedChildren(child, referenceLayer, graphicContext, clipRect, scrollOffset);
				}
				else if (child.coreStyle.getKeyword(child.coreStyle.display) == CSSKeywordValue.BLOCK)
				{
					child.render(graphicContext, clipRect, scrollOffset);
				}
			}
			
			child = child.nextSibling;
		}
	}
	
	/**
	 * Render all the BlockBoxRenderer which
	 * belong to the same stacking context as this BlockBoxRenderer
	 */
	private function renderBlockContainerChildren(rootElementRenderer:ElementRenderer, referenceLayer:LayerRenderer, graphicContext:GraphicsContext, clipRect:RectangleVO, scrollOffset:PointVO):Void
	{
		var child:ElementRenderer = rootElementRenderer.firstChild;
		while(child != null)
		{
			//check that the child is not positioned, as if it is an auto z-index positioned
			//element, it will be on the same layerRenderer but should not be rendered as 
			//a block container children
			if (child.layerRenderer == referenceLayer)
			{
				//TODO 3 : must add more condition, for instance, no float
				if (child.isReplaced() == false && child.coreStyle.getKeyword(child.coreStyle.display) != INLINE_BLOCK && child.isInlineLevel() == false)
				{
					child.render(graphicContext, clipRect, scrollOffset);
					renderBlockContainerChildren(child, referenceLayer, graphicContext, clipRect, scrollOffset);
				}
			}
			
			child = child.nextSibling;
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE LAYOUT METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * layout all of the block box children in normal 
	 * flow and floated children
	 */
	override private function layoutChildren():Void
	{
		//first, update list of floated elements affecting
		//the layout of children of the block box, those are all the 
		//floated elements in the same block formatting
		//context
		
		//if this block box is a block formatting root,
		//then it needs to reset its floated element list,
		//as it's children can't be affected by floated elements
		//from another block formatting context
		if (establishesNewBlockFormattingContext() == true)
		{
			//this flag ensure that floated element list is reseted
			//if layout is in progress and a floated element was found
			//during layout
			if (_isLayingOut == false)
			{
				floatsManager.init();
			}
		}
		//else this block box retrives floated element from its containing block
		//and convert their bounds to its own bounds
		else
		{
			var containingBlockAsBlock:BlockBoxRenderer = cast(containingBlock);
			//TODO : convert float in containing block space to this space
			//floatsManager.convertToSpace(this, containingBlockAsBlock.floatsManager, containingBlockAsBlock);
		}
		
		_isLayingOut = true;
		
		var shouldLayoutAgain:Bool = false;
		
		//once layout is done, store the total height of
		//the laid out children, which will be sued as content
		//height for this block if its height is defined as 'auto'
		var childrenHeight:Float = 0;
		
		//children are either all block level or all inline level
		//(exluding floated and absolutely positioned element), 
		//so this block either formatting them as blocks are lines
		if (childrenInline() == false)
		{
			shouldLayoutAgain = layoutBlockChildrenAndFloats();
			
			//retrieve block children total height
			childrenHeight = _childPosition.y;
		}
		else
		{
			shouldLayoutAgain = layoutInlineChildrenAndFloats();
			
			//retrieve line boxes total height
			childrenHeight = _lineBoxPosition.y;
			
			//now that all children's inlineBoxes have been
			//laid out, their bounds can be updated
			updateInlineChildrenBounds(this);
		} 
		
		//the width of this block box might need to be re-computed if it uses its 'shrink-to-width'
		//width which roughly matches the width of its descendant
		//'shrink-to-fit' is used for block formatting root with an auto width
		//once 'shrink-to-fit' width is found, layout needs to be done again
		//
		//note : 'shrink-to-fit' is done here, this way all floated elements in block formatting have been
		//found
		//TODO : should not include initial containing block
		if (establishesNewBlockFormattingContext() == true && coreStyle.isAuto(coreStyle.width) == true)
		{
			
		}
		
		//if the height of this block box is auto, it depends
		//on its content height, and can computed now that all
		//children are laid out
		if (coreStyle.isAuto(coreStyle.height) == true)
		{
			//at this point children height is known and might match block children, with
			//appropriately collapsed margins
			//or line boxes height based on formatting
			//
			//only normal flow children's height (not absolutely positioned or floated)
			//are taken into account
			
			//in addition if this block box establishes a new block formatting and has floated descedant whose bottom
			//are below its bottom, then the height includes those floated elements
			if (establishesNewBlockFormattingContext() == true)
			{
				//TODO : if floats bounds higher, use instead for height
			}
			
			//constrain children height if needed
			if (coreStyle.isNone(coreStyle.maxHeight) == false)
			{
				if (childrenHeight > coreStyle.usedValues.maxHeight)
				{
					childrenHeight = coreStyle.usedValues.maxHeight;
				}
			}
			
			if (childrenHeight < coreStyle.usedValues.minHeight)
			{
				childrenHeight = coreStyle.usedValues.minHeight;
			}
			
			//bounds height matches the border box
			bounds.height = childrenHeight + coreStyle.usedValues.paddingTop + coreStyle.usedValues.paddingBottom;
		}
		
		_isLayingOut = false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PRIVATE LAYOUT METHODS
	//////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * Called when all children are blocks. 
	 * Layout them as well as floated children
	 * 
	 * @return wether layout need to be restarted. Happens
	 * when a floated child is first found, layout of the 
	 * block formatting context must be done again as the float
	 * may influence previous block's layout
	 */
	private function layoutBlockChildrenAndFloats():Bool
	{
		//holds the x,y position, in this block box space where
		//to position the next child
		_childPosition.x = 0;
		_childPosition.y = 0;
			
		//loop in all children
		var child:ElementRenderer = firstChild;
		while (child != null)
		{
			//if child can introduce clearance it will be placed below previous
			//left, right or both float based on the value of the clear style
			if (child.canHaveClearance() == true)
			{
				//TODO : when clearing, should only clear floats declared before in document order
				floatsManager.clearFloats(child.coreStyle.clear, _childPosition.y);
			}
			//absolutely positioned child are not positioned here
			if (child.isPositioned() == false || child.isRelativePositioned() == true)
			{
				//if the child is not a float
				if (child.isFloat() == false)
				{
					//if it is a block box not establishing a new block formatting
					if (child.establishesNewBlockFormattingContext() == false && child.isBlockContainer() == true)
					{
						//add its own margin to the x/y position, as it is the position
						//of its border box. Top margin is collapsed with adjoining margins
						//if needed
						//floats are not taken into account when positioning it but if it creates
						//line boxes they might be shortened by those floats
						_childPosition.y += child.getCollapsedTopMargin();
						
						//update postion of child
						child.bounds.x = child.coreStyle.usedValues.marginLeft;
						child.bounds.y = _childPosition.y;
						
						//child can now be layout, it needs to know its own x and y bounds
						//before laying out its children to correctly deal with floated elements,
						//as child need to convert floated elements to their own space
						child.layout(true);
					}
					//here the child is either a replaced block level element or a block box
					//establishing a new block formatting
					else
					{
						//the child must first be laid out so that its width and height are known
						child.layout(true);
						
						//this child x and y position is influenced by floated elements, so the first y position
						//where this child can fit given the floated elements must be found
						var childMarginWidth:Float = child.bounds.width + child.coreStyle.usedValues.marginLeft + child.coreStyle.usedValues.marginRight;
						var contentWidth:Float = bounds.width - coreStyle.usedValues.paddingLeft - coreStyle.usedValues.paddingRight;
						_childPosition.y = floatsManager.getFirstAvailableYPosition(_childPosition.y, childMarginWidth, contentWidth);
						
						//TODO : for x add left float offset
						//add child margins. Top margin is collapsed with
						//adjoining margins if needed
						_childPosition.y += child.getCollapsedTopMargin();
					}
					
					//add the current's child height so that next block child will be placed below it
					_childPosition.y += child.bounds.height;
					//add child bottom margin, collapsed with adjoining margins
					//if needed
					_childPosition.y += child.getCollapsedBottomMargin();
				}
				//here the child is a floated element
				else
				{
					//it must first be laid out so that its width and height are known
					child.layout(true);
					
					//each a float is found, it is stored and the layout is re-started at
					//the first parent block formatting root, so do nothing if the float
					//was already found to prevent infinite loop
					if (floatsManager.isAlreadyRegistered(child) == false)
					{
						registerFloatedElement(child, _childPosition);
						return true;
					}
				}
			}
			
			child = child.nextSibling;
		}
		
		return false;
	}
	
	//TODO : implement
	private function registerFloatedElement(floatedElement:ElementRenderer, childPosition:PointVO):Void
	{
		var contentWidth:Float = bounds.width - coreStyle.usedValues.paddingLeft - coreStyle.usedValues.paddingRight;
		var floatBounds:RectangleVO = floatsManager.registerFloat(floatedElement, childPosition, contentWidth);
		
		floatedElement.bounds.x = floatBounds.x + floatedElement.coreStyle.usedValues.marginLeft;
		floatedElement.bounds.y = floatBounds.y + floatedElement.coreStyle.usedValues.marginTop;
		
		var xOffset:Float = 0;
		var yOffset:Float = 0;
		
		var blockFormattingRoot:ElementRenderer = this;
		
		while (blockFormattingRoot.establishesNewBlockFormattingContext() == false)
		{
			if (blockFormattingRoot.parentNode == null)
			{
				break;
			}
			blockFormattingRoot = blockFormattingRoot.parentNode;
		}
		
		//TODO : convert float in current space to block root space
		//blockFormattingRoot.addFloatedElementToBlockFormattingRoot(floatedElement);
	}

	/**
	 * When all children are inline level, format them as 
	 * lines. Also format floated children
	 */
	private function layoutInlineChildrenAndFloats():Bool
	{
		//reset the array of line boxes before layout
		lineBoxes = new Array<LineBox>();
		
		//this will hold the x and y position where
		//to place the next line box, relative to this
		//block box
		_lineBoxPosition.x = 0;
		_lineBoxPosition.y = 0;
		
		var firstLineBox:LineBox = createLineBox(_lineBoxPosition);
		
		//during layout hold the inline box renderer currently laying out descendant inline boxes
		var openedElementRendererStack:Array<ElementRenderer> = new Array<ElementRenderer>();
		
		//do layout, return the last created inline box
		var lastInlineBox:InlineBox = doLayoutInlineChildrenAndFloats(this, firstLineBox, firstLineBox.rootInlineBox,
		openedElementRendererStack, _lineBoxPosition);
		
		//layout the last line
		var lastLineBox:LineBox = lineBoxes[lineBoxes.length - 1];
		lastLineBox.layout(true, lastInlineBox);
		//add last line box height so that the total line boxes height
		//is known
		_lineBoxPosition.y += lastLineBox.bounds.height;
		
		return false;
	}
	
	/**
	 * Create and return a new line box. Position
	 * it relative to its containing block 
	 */
	private function createLineBox(lineBoxPosition:PointVO):LineBox
	{
		//the width of a line box is the client width of the containing block minus
		//the margin box width of any floated element intersecting with the line
		//
		//TODO : remove left and float offset at the current y position
		var availableWidth:Float = coreStyle.usedValues.width;
		
		//the minimum height that the line box can have is given by the
		//line-height style of the containing block
		var minimumHeight:Float = coreStyle.usedValues.lineHeight;
		
		var lineBox:LineBox = new LineBox(this, availableWidth, minimumHeight, true);
		
		//TODO : get x float offset
		//position the line box in x and y relative to the containing block (this)
		//taking floated elements into account
		lineBox.bounds.x = lineBoxPosition.x;
		lineBox.bounds.y = lineBoxPosition.y;
		
		lineBoxes.push(lineBox);
		
		return lineBox;
	}
	
	/**
	 * When a line box was filled with inlineBoxes,
	 * lay it out, which set all its inlineBoxes x and y
	 * relative to the top left of the line box.
	 * 
	 * Returns the inlineBox where all subsequent inlineBox
	 * can be attached
	 */
	private function layoutLineBox(lineBox:LineBox, lineBoxPosition:PointVO, openedElementRenderers:Array<ElementRenderer>):InlineBox
	{
		lineBox.layout(false, null);
		
		//TODO : set x to float offset x
		lineBoxPosition.y += lineBox.bounds.height;
		
		//TODO : get x offset at new y
		var newLineBox:LineBox = createLineBox(lineBoxPosition);
		
		//will be returned as the inline box where next inline boxes
		//can be attached to
		var currentInlineBox:InlineBox = newLineBox.rootInlineBox;
		
		//create new inline boxes for all the inline box renderer which still have
		//children to layout, and add them to the new line box
		var length:Int = openedElementRenderers.length;
		for (i in 0...length)
		{
			//all inline boxes are attached as child of the previously created inline box
			//and not as sibling to respect the hierarchy of the previous line. Hierarchey
			//must be preserved to render with the right z-order and to get the right
			//bounds for each inline box renderer
			var childInlineBox:InlineBox = new InlineBox(openedElementRenderers[i]);
			openedElementRenderers[i].inlineBoxes.push(childInlineBox);
			currentInlineBox.appendChild(childInlineBox);
			currentInlineBox = childInlineBox;
		}
		
		return currentInlineBox;
	}
	
	/**
	 * Actually layout inline box renderer by 
	 * traversing all inline box renderer children
	 * recursively
	 * @param	elementRenderer the current element renderer being laid out in line box
	 * @param	lineBox the current line box where inlineBox can be inserted
	 * @param	inlineBox the current inlineBox where other inlineBox can be attached to create the inline box tree
	 * for the current line box
	 * @param	openedElementRenderers the stack of inline box renderer which still have children to layout
	 * @param	lineBoxPosition the current x and y position where to place the next line box relative to 
	 * the containing block (this)
	 * @return the inlineBoxw where subsequent inline boxes can be attached to
	 */
	private function doLayoutInlineChildrenAndFloats(elementRenderer:ElementRenderer, lineBox:LineBox, inlineBox:InlineBox, openedElementRenderers:Array<ElementRenderer>, lineBoxPosition:PointVO):InlineBox
	{
		//loop in all the child of the container
		var child:ElementRenderer = elementRenderer.firstChild;
		while(child != null)
		{
			//absolutely positionned children can't be formatted in an inline formatting context
			if (child.isPositioned() == false || child.isRelativePositioned() == true)
			{
				//here the child is floated, its floated position is stored and the 
				//whole layout of the block formatting will be done again with this added
				//floated element
				//
				//TODO : can only restart inline formatting of containing block ?
				if (child.isFloat() == true)
				{
					//TODO : store float, then restart layout of first root block container ancestor
					//create common method with block formatting float behaviour ?
				}
				//here the child is a TextRenderer, which has as many text inline box
				//as needed to represent all the content of the TextRenderer
				else if (child.isText() == true)
				{
					//insert the array of created inline boxes into the current line. As many new line boxes
					//as needed are created to hold all those text inline boxes
					var textLength:Int = child.inlineBoxes.length;
					for (i in 0...textLength)
					{
						var lineIsFull:Bool = lineBox.insert(child.inlineBoxes[i], inlineBox);
						//if inserting this text would make the line full, create a new line for it
						if (lineIsFull == true)
						{
							//layout current line, create a new one and return the inlineBox where
							//the next text inlineBox should be attached
							inlineBox = layoutLineBox(lineBox, lineBoxPosition, openedElementRenderers);
							//get a reference to the newly created line box
							lineBox = lineBoxes[lineBoxes.length - 1];
							//text inline box can now be inserted in the new line box
							//
							//TODO : instead of just adding last text inline box, should insert all
							//unbreakable elements of last line box
							lineBox.insert(child.inlineBoxes[i], inlineBox);
						}
					}
				}
				//here the child either establishes a new formatting context, for instance an inline-block
				//element or it is replaced, like an inline image renderer
				else if (child.establishesNewBlockFormattingContext() == true || child.isReplaced() == true)
				{
					//for inline-block, they need to be laid out 
					//before they are inserted so that their width and height 
					//is known
					if (child.isReplaced() == false)
					{
						child.layout(true);
					}
					
					//those element generate only one inline box so
					//that they can be inserted in an inline formatting
					var childInlineBox:InlineBox = child.inlineBoxes[0];
					
					//set the bounds of the inline box and its margins
					childInlineBox.bounds.height = child.bounds.height;
					childInlineBox.bounds.width = child.bounds.width;
					childInlineBox.marginLeft = child.coreStyle.usedValues.marginLeft;
					childInlineBox.marginRight = child.coreStyle.usedValues.marginRight;
					
					//insert the inline box, create a new line box if needed to hold the inline box
					var lineIsFull:Bool = lineBox.insert(childInlineBox, inlineBox);
					if (lineIsFull == true)
					{
						inlineBox = layoutLineBox(lineBox, lineBoxPosition, openedElementRenderers);
						lineBox = lineBoxes[lineBoxes.length - 1];
						lineBox.insert(childInlineBox, inlineBox);
					}
				}
				//here the child is an inline box renderer, which will create one inline box for each
				//line box its children are in
				else if (child.firstChild != null)
				{
					//the child must first be laid out so that
					//it computes its dimensions and font metrics
					child.layout(true);
					
					//reset inline boxes before adding new ones
					child.inlineBoxes = new Array<InlineBox>();
					
					//create the first inline box for this inline box renderer
					var childInlineBox:InlineBox = new InlineBox(child);
					child.inlineBoxes.push(childInlineBox);
					
					var childUsedValues:UsedValuesVO = child.coreStyle.usedValues;
					
					//the first inline box created by an inline box renderer has its left margin and padding
					childInlineBox.marginLeft = childUsedValues.marginLeft;
					childInlineBox.paddingLeft = childUsedValues.paddingLeft;
					//the left margin and padding are added as an unbreakable width, as it can't be separated
					//from next inline box until a break opportunity occurs
					lineBox.addUnbreakableWidth(childUsedValues.marginLeft + childUsedValues.paddingLeft);
					
					//attach the child inline box to its parent inline box to form the inline box tree for the current
					//line box
					inlineBox.appendChild(childInlineBox);

					//store the inline box renderer. Each time a new line box is created
					//by laying out a descandant of this inline box renderer, a new inline box
					//with a reference to this inline box renderer will be added to the new
					//line box. This way the inline box renderer will have one inline box
					//for each line box where it has descendant
					openedElementRenderers.push(child);
					
					//format all the children of the inline box renderer recursively.
					//a reference to the last added inline box is returned, so that it can
					//be used as a starting point when laying out the siblings of the 
					//inline box renderer
					inlineBox = doLayoutInlineChildrenAndFloats(child, lineBox, childInlineBox, openedElementRenderers, lineBoxPosition);
					
					//now that all of the descendant of the inline box renderer have been laid out,
					//remove the reference to this inline box renderer so that when a new line box
					//is created, no new inline box pointing to this inline box renderer are created
					openedElementRenderers.pop();
					
					//The current inline box must also be set to the parent inline box so that no more
					//inline boxes are added to this inline box as it is done laying out its child inline boxes
					inlineBox = inlineBox.parentNode;
					
					//The right margin and padding is added to the last generated inline box of the current inline
					//box renderer
					var lastInLineBox:InlineBox = child.inlineBoxes[child.inlineBoxes.length - 1];
					lastInLineBox.marginRight = childUsedValues.marginRight;
					lastInLineBox.paddingRight = childUsedValues.paddingRight;
					lineBox.addUnbreakableWidth(childUsedValues.marginRight + childUsedValues.paddingRight);
				}
			}
			
			child = child.nextSibling;
		}
	
		return inlineBox;
	}
	
	/**
	 * Update the bounds, relative top the containing
	 * block (this) of all the normal flow inline
	 * children
	 */
	private function updateInlineChildrenBounds(elementRenderer:ElementRenderer):Void
	{
		//loop in all inline children
		var child:ElementRenderer = elementRenderer.firstChild;
		while(child != null)
		{
			//only compute bounds of normal flow children (no float and no absolut positioned)
			if ((child.isPositioned() == false || child.isRelativePositioned() == true) && child.isFloat() == false)
			{
				//recurse down the rendering tree
				if (child.firstChild != null)
				{
					updateInlineChildrenBounds(child);
				}
				
				//reset bounds of child
				child.bounds.width = 0;
				child.bounds.height = 0;
				child.bounds.x = 50000;
				child.bounds.y = 50000;
				
				//bounds of child is bounds of all its inline boxes, which 
				//might be any number of inline boxes for inline container
				//or just one for inline-block or replaced elements
				var inlineBoxesLength:Int = child.inlineBoxes.length;
				for (i in 0...inlineBoxesLength)
				{
					var inlineBox:InlineBox = child.inlineBoxes[i];
					
					//TODO : should be implemented on LineBox
					if (inlineBox.firstChild != null)
					{
						updateInlineBoxBounds(inlineBox);
					}
			
					//inlineBox bounds are relative to their line box, so the
					//x and y of the line box needs to be added to get the inline
					//box bounds in the space of the containing block
					_inlineBoxGlobalBounds.width = inlineBox.bounds.width;
					_inlineBoxGlobalBounds.height = inlineBox.bounds.height;
					
					//TODO : lineBox should never be null at this point
					if (inlineBox.lineBox != null)
					{
						_inlineBoxGlobalBounds.x = inlineBox.bounds.x + inlineBox.lineBox.bounds.x;
						_inlineBoxGlobalBounds.y = inlineBox.bounds.y + inlineBox.lineBox.bounds.y;
					}
					
					GeomUtils.addBounds(_inlineBoxGlobalBounds, child.bounds);
				}
			}
			
			child = child.nextSibling;
		}
	}
	
	/**
	 * Update the bound of a container inline box whose
	 * bounds depends on its descendant inline boxes
	 * 
	 * TODO : should actually implemented by LineBox during
	 * layout method
	 */
	private function updateInlineBoxBounds(inlineBox:InlineBox):Void
	{
		inlineBox.bounds.x = 50000;
		inlineBox.bounds.y = 50000;
		inlineBox.bounds.width = 0;
		inlineBox.bounds.height = 0;
		
		var child:InlineBox = inlineBox.firstChild;
		while (child != null)
		{
			GeomUtils.addBounds(child.bounds, inlineBox.bounds);
			
			child = child.nextSibling;
		}
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE MARGIN COLLAPSING METHOD
	//////////////////////////////////////////////////////////////////////////////////////////
	
	override private function collapseTopMarginWithFirstChildTopMargin():Bool
	{ 
		//TODO : should be first normal flow child as well
		if (firstChild == null)
		{
			return false;
		}
		
		//TODO : should check on first normal flow child
		if (firstChild.isBlockContainer() == false)
		{
			return false;
		}
		
		if (establishesNewBlockFormattingContext() == true)
		{
			return false;
		}
		
		if (coreStyle.usedValues.paddingTop != 0)
		{
			return false;
		}
		
		return true;
	}
	
	/**
	 * same as collapseTopMarginWithFirstChildTopMargin
	 * for bottom margin
	 */
	override private function collapseBottomMarginWithLastChildBottomMargin():Bool
	{ 
		return false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PUBLIC HELPER METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Overriden as BlockBoxRenderer can also create a new layer
	 * if the overflow x or y style value is different from visible
	 */
	override public function createOwnLayer():Bool
	{
		//check first wether it should create a new layer
		//anyway
		var createOwnLayer:Bool = super.createOwnLayer();
		
		if (createOwnLayer == true)
		{
			return true;
		}
		
		return canAlwaysOverflow() != true;
	}
	
	/**
	 * Determine wether the ElementRenderer
	 * establishes a new block formatting context for
	 * its children or participate in its
	 * parent block formatting context
	 */
	override public function establishesNewBlockFormattingContext():Bool
	{
		var establishesNewBlockFormattingContext:Bool = false;
		
		//floats always establishes new block formatting context
		if (isFloat() == true)
		{
			establishesNewBlockFormattingContext = true;
		}
		//block box renderer which may hide their overflowing
		//children always start a new block formatting context
		else if (canAlwaysOverflow() == false)
		{
			establishesNewBlockFormattingContext = true;
		}
		//positioned element which are not relative always establishes new block context
		else if (isPositioned() == true && isRelativePositioned() == false)
		{
			establishesNewBlockFormattingContext = true;
		}
		else
		{
			switch (coreStyle.getKeyword(coreStyle.display))
			{
				//element with an inline-block display style
				//always establishes a new block formatting context
				case INLINE_BLOCK:
				establishesNewBlockFormattingContext = true; 
		
				default:
			}
		}
		
		//in the other cases, the block particpates in its parent's
		//block formatting context
		
		return establishesNewBlockFormattingContext;
	}
	
	override public function isBlockContainer():Bool
	{
		return true;
	}
	
	/**
	 * Determine wether the children of this block box
	 * are all block level or if they are all inline level
	 * elements
	 * 
	 * @return true if at least one child is inline level
	 */
	override public function childrenInline():Bool
	{	
		var child:ElementRenderer = firstChild;
		while(child != null)
		{
			if (child.isInlineLevel() == true)
			{
				//floated and absolutely positioned element are not taken into
				//account
				if (child.isFloat() == false)
				{
					if (child.isPositioned() == false || child.isRelativePositioned() == true)
					{
						return true;
					}
				}
			}
			
			child = child.nextSibling;
		}
		return false;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE HELPER METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * overriden as a block box renderer might be rendered as if
	 * it creates its own layer, based on its computed styles
	 * value
	 */
	override private function rendersAsIfCreateOwnLayer():Bool
	{
		if (coreStyle.getKeyword(coreStyle.display) == INLINE_BLOCK)
		{
			return true;
		}
		else if (isFloat() == true)
		{
			return true;
		}
		
		return false;
	}
	
	/**
	 * Overriden, has if this block box renderer has its own
	 * layer, it must not use the scrollLeft and scrollTop
	 * of its layer when rendering background, as they
	 * should only apply to child element renderers and layers
	 */
	override private function getBackgroundBounds(scrollOffset:PointVO):RectangleVO
	{
		var backgroundBounds:RectangleVO = super.getBackgroundBounds(scrollOffset);
		
		if (_hasOwnLayer == true)
		{
			backgroundBounds.x += layerRenderer.scrollLeft;
			backgroundBounds.y += layerRenderer.scrollTop;
		}
		
		return backgroundBounds;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// PRIVATE HELPER METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Determine wether this BlockBoxRenderer always overflows
	 * in both x and y axis. If either overflow x or y
	 * is deifferent from visible, then it is considered to
	 * not always overflow
	 */
	private function canAlwaysOverflow():Bool
	{	
		switch (coreStyle.getKeyword(coreStyle.overflowX))
		{
			case VISIBLE:
				
			default:
				return false;
		}
		
		switch (coreStyle.getKeyword(coreStyle.overflowY))
		{
			case VISIBLE:
				
			default:
				return false;
		}
		
		return true;
	}
}