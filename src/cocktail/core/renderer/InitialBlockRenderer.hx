/*
 * Cocktail, HTML rendering engine
 * http://haxe.org/com/libs/cocktail
 *
 * Copyright (c) Silex Labs
 * Cocktail is available under the MIT license
 * http://www.silexlabs.org/labs/cocktail-licensing/
*/
package cocktail.core.renderer;

import cocktail.core.background.BackgroundManager;
import cocktail.core.dom.Node;
import cocktail.core.html.HTMLElement;
import cocktail.core.layer.InitialLayerRenderer;
import cocktail.port.NativeElement;
import cocktail.core.geom.GeomData;
import cocktail.core.layout.LayoutData;
import cocktail.core.css.CoreStyle;
import haxe.Log;
import cocktail.core.renderer.RendererData;
import cocktail.core.layer.LayerRenderer;
import cocktail.core.font.FontData;

/**
 * This is the root ElementRenderer of the rendering
 * tree, generated by the HTMLHTMLElement, which is the root
 * of the DOM tree
 * 
 * @author Yannick DOMINGUEZ
 */
class InitialBlockRenderer extends BlockBoxRenderer
{
	/**
	 * class constructor.
	 */
	public function new(node:HTMLElement) 
	{
		super(node);
		
		//as this is the root of the rendering
		//tree, it is considered to be its
		//own containing block
		//
		//TODO 3 :maybe not very clean, trouble is that
		//addedToRenderingTree never called as initial 
		//block is never attached to a parent
		containingBlock = this;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE ATTACHEMENT METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Overriden as initial block renderer always create
	 * a new intitial layer renderer.
	 */
	override private function attachLayer():Void
	{
		layerRenderer = new InitialLayerRenderer(this);
	}
	
	/**
	 * never register with containing block as it is
	 * itself
	 */
	override private function registerWithContaininingBlock():Void
	{
		
	}
	
	/**
	 * same as above for unregister
	 */
	override private function unregisterWithContainingBlock():Void
	{
		
	}

	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE INVALIDATION METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * As the initial block renderer has no containing block,
	 * do nothing
	 */
	override private function invalidateContainingBlock(styleName:String):Void
	{
		
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE LAYOUT METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * Overriden as the initial containing block always takes the size
	 * of the viewport
	 */
	override private function layoutSelfIfNeeded(forceLayout:Bool):Void
	{
		//only do if necessary
		if (_needsLayout == false && forceLayout == false)
		{
			return;
		}
		
		var viewportData:ContainingBlockVO = getWindowData();
		
		coreStyle.usedValues.width = viewportData.width;
		coreStyle.usedValues.height = viewportData.height;
		
		bounds.x = 0;
		bounds.y = 0;
		bounds.width = viewportData.width;
		bounds.height = viewportData.height;
		globalBounds.x = 0;
		globalBounds.y = 0;
		globalBounds.width = viewportData.width;
		globalBounds.height = viewportData.height;

		//reset dirty flag
		_needsLayout = false;
	}
	
	/**
	 * shrink-to-fit width never applies to the initial 
	 * container which always has the same size as
	 * the viewport's
	 */
	override private function applyShrinkToFitIfNeeded(layoutState:LayoutStateValue):Void
	{
		
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PUBLIC HELPER METHODS
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * The initial block renderer is always considered positioned,
	 * as it always lays out the positioned children for whom it is
	 * the first positioned ancestor
	 */
	override public function isPositioned():Bool
	{
		return true;
	}
	
	/**
	 * The initial block container always establishes a block formatting context
	 * for its children
	 */
	override public function establishesNewBlockFormattingContext():Bool
	{
		return true;
	}
	
	/**
	 * Overriden as initial block container alwyas establishes
	 * creates the root LayerRenderer of the
	 * LayerRenderer tree
	 */
	override public function createOwnLayer():Bool
	{
		return true;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN PRIVATE HELPER METHODS
	//////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * The dimensions of the initial
	 * block renderer are always the same as the Window's
	 */
	override public function getContainerBlockData():ContainingBlockVO
	{
		return getWindowData();
	}
	
	/**
	 * Returns itself as containing block, which is used
	 * during layout
	 */
	override private function getContainingBlock():FlowBoxRenderer
	{	
		return this;
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////
	// OVERRIDEN GETTER
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/**
	 * For the initial container, the bounds and
	 * global bounds are the same
	 */
	override private function get_globalBounds():RectangleVO
	{
		return bounds;
	}
	
}