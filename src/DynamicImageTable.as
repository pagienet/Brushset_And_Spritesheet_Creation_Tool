package
{
	import com.quasimondo.tumblr.TumblrPhoto;
	import com.quasimondo.tumblr.TumblrPhotoPost;
	
	import flash.display.Bitmap;
	import flash.display.PixelSnapping;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class DynamicImageTable extends Sprite
	{
		private var _columnRatios:Vector.<Number>;
		private var _totalRatios:Number;
		private var _width:Number;
		private var _padding:Number;
		
		private var columns:Vector.<Sprite>;
		private var columnHeights:Vector.<Number>;
		private var columnWidths:Vector.<Number>;
		private var columnTimers:Vector.<int>;
		private var images:Vector.<Vector.<Bitmap>>;
		private var _addOuterPadding:Boolean;
		private var columnsTimer:uint;
		
		
		public function DynamicImageTable( columnRatios:Vector.<Number>, columnOffsets:Vector.<Number>,width:Number, padding:Number, addOuterPadding:Boolean = false)
		{
			this.opaqueBackground = 0xff808080;
			
			this.tabChildren = false;
			this.mouseChildren = false;
			if ( columnRatios.length != columnOffsets.length ) 
			{
				throw( new Error("columns don't match"));
			}
			
			_columnRatios= columnRatios;
			_width=width;
			_padding=padding;
			_addOuterPadding = addOuterPadding;
			columnHeights = new Vector.<Number>(_columnRatios.length,false);
			columnWidths = new Vector.<Number>(_columnRatios.length,false);
			columnTimers  = new Vector.<int>(_columnRatios.length,false);
			images = new Vector.<Vector.<Bitmap>>();
			
			
			columns = new Vector.<Sprite>();
			for ( var i:int = 0; i < columnRatios.length; i++ )
			{
				var col:Sprite = new Sprite();
				col.y = columnOffsets[i];
				columns.push( col );
				addChild(col);
			}
			
			redraw();
		}
		
		
		public function addBitmap( bitmap:Bitmap, columnIndex:int = -1 ):void
		{
			if ( columnIndex == -1 )
			{
				columnIndex = getNextFreeColumnIndex();
			} 
			
			while ( images.length <= columnIndex )
			{
				images[images.length] = new Vector.<Bitmap>();
			}
			
				
			bitmap.smoothing = true;
			//bitmap.pixelSnapping = PixelSnapping.ALWAYS;
			bitmap.width = 100;
			bitmap.scaleY = bitmap.scaleX;
			//bitmap.cacheAsBitmapMatrix = bitmap.transform.matrix;
			//bitmap.cacheAsBitmap = true;
			
			bitmap.y = columnHeights[columnIndex];
			columnHeights[columnIndex] += bitmap.height + _padding * (100 / columnWidths[columnIndex] ); 
			columns[columnIndex].addChild( bitmap );
			images[columnIndex].push(bitmap);
			
		}
		
		
		
		private function getColumnIndex( bitmap:Bitmap ):int
		{
			for ( var i:int = 0; i < columns.length; i++ )
			{
				if ( columns[i].contains(bitmap ) ) return i;
			}
			return -1;
		}
		
		
		
		public function getNextFreeColumnIndex():int
		{
			var columnIndex:int = 0;
			var bestTop:Number = columns[0].y + columns[0].height;
			for ( var i:int = 1; i < columns.length; i++ )
			{
				var top:Number = columns[i].y + columns[i].height;
				if ( top < bestTop )
				{
					bestTop = top;
					columnIndex = i;
				}
			}
			return columnIndex;
		}
		
		public function getColumnWidth( index:int ):Number
		{
			return columnWidths[index];
		}
		
		public function getColumnHeight( index:int ):Number
		{
			return columns[index].height;
		}
		
		public function setWidth( value:Number ):void
		{
			_width = value;
			
			var oldImageY:Array = [];
			var oldImage:Array = [];
			for ( var i:int = 0; i < columns.length; i++ )
			{
				var top:Number = columns[i].y;
				if (  images.length > i && images[i].length > 0 )
				{
					for ( var j:int = 0; j < images[i].length; j++ )
					{
						if ( (images[i][j].y + images[i][j].height * 0.5) * columns[i].scaleY + top >= stage.stageHeight * 0.5 )
						{
							oldImageY[i] =  (images[i][j].y + images[i][j].height * 0.5) * columns[i].scaleY
							oldImage[i] = images[i][j];
							break;
						}
					}
				} else {
					oldImageY[i] =  0;
					oldImage[i] = null;
				}
			}
			redraw();
			fixPadding();
			for ( i = 0; i < columns.length; i++ )
			{
				if ( oldImage[i] != null )
				{
					columns[i].y += oldImageY[i] - (oldImage[i].y + oldImage[i].height * 0.5) * columns[i].scaleY;
					if (columns[i].y > 0 ) columns[i].y = 0;
				}
			}
		}
		
		private function fixPadding():void
		{
			for ( var i:int = 0; i < images.length; i++ )
			{
				var offsetY:Number = 0;
				for ( var j:int = 0; j < images[i].length; j++ )
				{
					images[i][j].y =  Math.round(offsetY);
					offsetY += Math.round(images[i][j].height + _padding * (100 / columnWidths[i] )); 
				}
				columnHeights[i] = offsetY;
			}
		}
		
		private function get availableImageSpaceWidth():Number
		{
			return _width - (_columnRatios.length + ( _addOuterPadding ? 2 : -1)) * _padding;
			
		}
		
		public function redraw():void
		{
			
			var availWidth:Number = availableImageSpaceWidth;
			_totalRatios = 0;
			for ( var i:int = 0; i < _columnRatios.length ; i++ )
			{
				_totalRatios +=  _columnRatios[i];
			}
			var offsetX:Number = Math.round(_addOuterPadding ? _padding : 0);
			for ( i = 0; i < _columnRatios.length ; i++ )
			{
				
				columns[i].x =  Math.round(offsetX);
				columns[i].width = columnWidths[i] =  Math.round(availWidth * _columnRatios[i] / _totalRatios);
				offsetX += columns[i].width + _padding;
				columns[i].scaleY = columns[i].scaleX;
				
			}
			
			
			
		}
		
		
		public function getColumnIndexForX(mouseX:Number):int
		{
			var offsetX:Number = (_addOuterPadding ? _padding : 0) + columns[0].width;
			var idx:int = 0;
			while ( mouseX > offsetX && idx < columns.length - 1 )
			{
				idx++;
				offsetX +=  columns[idx].width  + _padding;
				
			}
			if ( mouseX > offsetX ) return -1;
			return idx;
		}
		
		public function setColumnOffsetAt(index:int, value:Number ):void
		{
			columns[index].y = value;
			redraw();
		}
		
		public function getColumnOffsetAt(index:int):Number
		{
			return columns[index].y;
		}
		
		public function removeOffsets(lineUpOnTop:Boolean = true ):void
		{
			if ( lineUpOnTop )
			{
				for ( var i:int = 0; i < columns.length; i++ )
				{
					
					columns[i].y = 0;
				}
			} else {
				var maxHeight:Number = columns[0].height;
				for ( i = 1; i < columns.length; i++ )
				{
					maxHeight = (maxHeight > columns[i].height ? columns[i].height : maxHeight);
				}
				for ( i = 0; i < columns.length; i++ )
				{
					columns[i].y = maxHeight - columns[i].height;
				}
			}
		}
		
		public function getBitmapAtPoint(p:Point):Bitmap
		{
			var result:Array = stage.getObjectsUnderPoint(p);
			for ( var i:int = 0; i < result.length; i++ )
			{
				if ( result[i] is Bitmap ) return result[i]
			}
			return null;
		}
		
		public function get top():Number
		{
			var minY:Number = 0;
			for ( var i:int = 0; i < columns.length; i++ )
			{
				
				minY = (minY > columns[i].y ? columns[i].y : minY);
			}
			return minY;
		}
		
		public function setColumnRatios(ratios:Vector.<Number>):void
		{
			
			var oldY:Array = []
			for ( var i:int = 0; i < columns.length; i++ )
			{
				oldY[i] = columns[i].mouseY;
			}
			
		
			_columnRatios = ratios;
			redraw();
			fixPadding();
			
			
			for (  i = 0; i < columns.length; i++ )
			{
				columns[i].y += (columns[i].mouseY - oldY[i]) * columns[i].scaleY;
				if ( columns[i].y > -y ) columns[i].y = -y;
			}
			
			
			
		}
		
		public function setColumnRatioAt(index:int, value:Number ):void
		{
			var oldY:Array = []
			for ( var i:int = 0; i < columns.length; i++ )
			{
				oldY[i] = columns[i].mouseY;
			}
			
			_columnRatios[index] = value;
			redraw();
			fixPadding();
			for (  i = 0; i < columns.length; i++ )
			{
				columns[i].y += (columns[i].mouseY - oldY[i]) * columns[i].scaleY;
				if ( columns[i].y > -y ) columns[i].y = -y;
			}
			
		}
		
		public function getColumnRatioAt(index:int):Number
		{
			return _columnRatios[index] ;
		}
		
		
		public function moveColumnBy(index:int, delta:Number, decayFactor:Number = 0):Boolean
		{
			clearTimeout(columnTimers[index]);
			columns[index].y += delta;
			delta *= decayFactor;
			if ( Math.abs(delta) > 0.02 )
			{
				columnTimers[index] = setTimeout(moveColumnBy,1000 / 60,index,delta,decayFactor);
			}
			return ( columns[index].y + columns[index].height > stage.stageHeight ) ;
		}
		
		public function moveColumnsBy( delta:Number, decayFactor:Number = 0):void
		{
			clearTimeout(columnsTimer);
			for  ( var index:int = 0; index < columns.length; index++ )
			{
				clearTimeout(columnTimers[index]);
				columns[index].y += delta;
				
				if ( columns[index].y + columns[index].height < scrollRect.height ) columns[index].y = scrollRect.height - columns[index].height;
				if ( columns[index].y > 0 ) columns[index].y = 0;
					
			}
			
			if ( Math.abs(delta * decayFactor) > 0.02 )
			{
				columnsTimer = setTimeout(moveColumnsBy,1000 / 60,delta * decayFactor,decayFactor);
			}
			
		}
		
		public function columnEndVisible():Boolean
		{
			for ( var i:int = 0; i < columns.length; i++ )
			{
			 	if ( columns[i].y + columns[i].height < stage.stageHeight ) return true;
			}
			return false;
		}
		
		public function getPaddingIndexAt( x:Number ):int
		{
			var offsetX:Number = (_addOuterPadding ? 0 : _padding * 0.5) ;
			var idx:int = -1;
			while (( Math.abs(x - offsetX) > 2 * _padding) && idx < columns.length-1 )
			{
				idx++;
				offsetX +=  columns[idx].width  + _padding;
				
			}
			if ( !_addOuterPadding ) idx++;
			if ( idx >= columns.length -1 ) idx = -1;
			return idx;
		}
		
		public function movePaddingAt(paddingIndex:int, offset:Number):void
		{
			var leftRatio:Number = 0;
			for ( var i:int = 0; i < paddingIndex+1 ; i++ )
			{
				leftRatio += _columnRatios[i];
			}
			var rightRatio:Number = _totalRatios - leftRatio;
			
			var leftWidth:Number = _width * leftRatio / _totalRatios;
			leftWidth += offset;
			var newLeftRatio:Number = leftWidth * _totalRatios / _width;
			var newRatios:Vector.<Number> = _columnRatios.concat();
			for ( var i:int = 0; i < paddingIndex+1 ; i++ )
			{
				newRatios[i] *= leftRatio / newLeftRatio;
			}
			
			var newRightRatio:Number =_totalRatios-newLeftRatio;
			for ( var i:int = paddingIndex+1; i < columns.length ; i++ )
			{
				newRatios[i] *= rightRatio / newRightRatio;
			}
			
			setColumnRatios( newRatios );
		}
		
		
		public function fixColumnOverflow():Boolean
		{
			var unaligned:Boolean = false;
			for (  var i:int = 0; i < columns.length; i++ )
			{
				if ( columns[i].y > -y ) {
					columns[i].y -=  0.33 *( columns[i].y + y);
					unaligned = true;
				}
			}
			return unaligned;
			
		}
		
		public function reset():void
		{
			for ( var i:int = 0; i < _columnRatios.length; i++ )
			{
				columnHeights[i] = 0;
				columnTimers[i] = 0;
				
				if ( images && i < images.length && images[i] )
				{
					for ( var j:int = 0; j < images[i].length; j++ )
					{
						images[i][j].bitmapData.dispose();
						images[i][j].parent.removeChild(images[i][j]);
					}
					images[i].length = 0;
				}
				columns[i].y = 0;
			}
		}
	}
}