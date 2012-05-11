package cocktail.core.renderer;
import cocktail.core.NativeElement;
import cocktail.core.geom.GeomData;

/**
 * ...
 * @author Yannick DOMINGUEZ
 */

class EmbeddedLineBox extends LineBox
{

	public function new(elementRenderer:ElementRenderer) 
	{
		super(elementRenderer);
		
		_bounds.width = elementRenderer.bounds.width;
		_bounds.height = elementRenderer.bounds.height;
	}
	
	override private function get_leadedAscent():Float 
	{
		return bounds.height + _elementRenderer.coreStyle.computedStyle.marginTop + _elementRenderer.coreStyle.computedStyle.marginBottom;
	}
	
	override private function get_leadedDescent():Float
	{
		return 0.0;
	}
	
	//TODO : messy ?
	override public function render(graphicContext:NativeElement):Void
	{
		_elementRenderer.render(graphicContext);
	}
	
	//TODO : messy ? return element renderer bounds, as embedded
	//element only have one line box
	override private function get_bounds():RectangleData
	{
		return _elementRenderer.bounds;
	}
}