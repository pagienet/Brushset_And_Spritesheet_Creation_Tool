package
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.ComboBox;
	import com.bit101.components.HBox;
	import com.bit101.components.Label;
	import com.bit101.components.NumericStepper;
	import com.bit101.components.PushButton;
	import com.bit101.components.Window;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.PNGEncoderOptions;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	public class BrushSetCreator extends Sprite
	{
		private var navHolder:HBox;
		private var folderPreview:DynamicImageTable;
		private var presets:BrushSetCreatorPreset;
		private var brushSizes:ComboBox;
		private var columns:NumericStepper;
		private var rows:NumericStepper;
		private var brushTexture:BitmapData;
		private var brushTextureHolder:Bitmap;
		private var placementHolder:Sprite;
		private var grid:Shape;
		private var dragBitmap:Bitmap;
		private var selectedMap:BitmapData;

		private var columnWidth:Number;

		private var rowHeight:Number;

		private var currentColumnIndex:int;

		private var currentRowIndex:int;
		private var addDragBitmapToTexture:Boolean;
		
		private var placements:Vector.<Vector.<BrushPlacementInfo>>;
		private var currentGridSelection:Bitmap;
		private var padding:NumericStepper;
		private var shiftIsPressed:Boolean;
		private var backgroundColor:ComboBox;
		private var allowUpscale:CheckBox;
		
		
		public function BrushSetCreator()
		{
			stage.scaleMode = "noScale";
			stage.align = "TL";
			
			presets = new BrushSetCreatorPreset(this, onPresetsChanged );
			presets.importFolder.addEventListener(Event.SELECT, onImportFolderChanged );
			initUI();
			
			onTextureChanged(null);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown );
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel );
			stage.addEventListener(Event.RESIZE, onResize);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown );
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp );
				
		}
		
		protected function onKeyUp(event:KeyboardEvent):void
		{
			if ( event.keyCode == Keyboard.SHIFT ) shiftIsPressed = false;
			
		}
		
		protected function onKeyDown(event:KeyboardEvent):void
		{
			if ( event.keyCode == Keyboard.SHIFT ) shiftIsPressed = true;
			if ( event.keyCode == Keyboard.DELETE )
			{
				if ( currentGridSelection != null )
				{
					currentColumnIndex = currentGridSelection.x / columnWidth;
					currentRowIndex = currentGridSelection.y / rowHeight;
					placementHolder.removeChild(placements[currentRowIndex][currentColumnIndex].map);
					placements[currentRowIndex][currentColumnIndex] = null;
				}
				
			}
		}
		
		protected function onResize(event:Event):void
		{
			if (folderPreview ) folderPreview.scrollRect = new Rectangle(0,0,300,stage.stageHeight-32);
			
			graphics.clear();
			graphics.beginFill(0xffe0e0e0);
			graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight );
			graphics.endFill();
			
			if ( grid )
			{
				var scale:Number = Math.min( stage.stageHeight - grid.y, stage.stageWidth  - grid.x ) / brushTexture.width;
				if ( scale > 1 ) scale = 1;
				if ( scale < 0.25 ) scale = 0.25;
				placementHolder.scaleX = placementHolder.scaleY = grid.scaleX = grid.scaleY = brushTextureHolder.scaleX = brushTextureHolder.scaleY = scale;
			}
		}		
		
		
		private function initUI():void
		{
			navHolder = new HBox(this,0,0);
			
			var setFolderBtn:PushButton = new PushButton(navHolder,0,0,"Set Import Folder", onSetImportFolder );
			new Label(navHolder,0,0,"Texture Size:");
			
			brushSizes = new ComboBox(navHolder,0,0,"Texture Size",[32,64,128,256,512,1024,2048]);
			brushSizes.selectedIndex = presets.textureIndex;
			brushSizes.addEventListener( Event.SELECT, onTextureChanged );
			
			backgroundColor = new ComboBox(navHolder,0,0,"BackgroundColor",[{label:"Black",value:0xff000000},{label:"White",value:0xffffffff},{label:"Transparent",value:0x00000000},{label:"Green",value:0xff00ff00}]);
			backgroundColor.selectedIndex = presets.backgroundIndex;
			backgroundColor.addEventListener( Event.SELECT, onTextureChanged );
			
			new Label(navHolder,0,0,"Columns:");
			columns = new NumericStepper(navHolder,0,0,onTextureChanged );
			columns.minimum = 1;
			columns.maximum = 64;
			columns.value = presets.columns;
			
			new Label(navHolder,0,0,"Rows:");
			rows = new NumericStepper(navHolder,0,0,onTextureChanged );
			rows.minimum = 1;
			rows.maximum = 64;
			rows.value = presets.rows;
			
			new Label(navHolder,0,0,"Padding:");
			padding = new NumericStepper(navHolder,0,0,onTextureChanged );
			padding.minimum = 0;
			padding.maximum = 16;
			padding.value = presets.padding;
			
			allowUpscale = new CheckBox(navHolder,0,0,"Allow Upscale", onTextureChanged );
			allowUpscale.selected = presets.allowUpscale;
			
			new PushButton(navHolder,0,0,"Save Texture", saveTexture );
				
				
			folderPreview = new DynamicImageTable(Vector.<Number>([1,1,1]),Vector.<Number>([0,0,0]),300,2,true);
			folderPreview.y = 32;
			folderPreview.x = 0;
			folderPreview.scrollRect = new Rectangle(0,0,300,stage.stageHeight-32);
			addChild(folderPreview);
			
			brushTextureHolder = new Bitmap(null,"auto",true);
			grid = new Shape();
			placementHolder = new Sprite();
			placementHolder.x = grid.x = brushTextureHolder.x = 308;
			placementHolder.y = grid.y = brushTextureHolder.y = folderPreview.y;
			
			addChild(brushTextureHolder);
			addChild(placementHolder);
			
			dragBitmap = new Bitmap(null,"auto",true);
			addChild(dragBitmap);
			dragBitmap.visible = false;
			
			addChild(grid);
			
			
		}
		
		private function onTextureChanged(event:Event):void
		{
			
			var newPlacements:Vector.<Vector.<BrushPlacementInfo>> = new Vector.<Vector.<BrushPlacementInfo>>();
			for ( var i:int = 0; i <rows.value;i++)
			{
				newPlacements[i] = new Vector.<BrushPlacementInfo>(columns.value,true);
			}
			if ( placements != null )
			{
				var addIdx:int = 0;
				for ( var row:int = 0; row < presets.rows ; row++ )
				{
					for ( var col:int = 0; col < presets.columns ; col++ )
					{
						if ( placements[row][col] != null )
						{
							if ( presets.rows == rows.value && presets.columns == columns.value )
							{
								newPlacements[row][col] =  placements[row][col];
								
							} else {
						
								newPlacements[int(addIdx / columns.value)][addIdx%columns.value] =  placements[row][col];
								addIdx++;
								if ( addIdx == columns.value * rows.value )
								{
									row =  presets.rows;
									break;
								}
							}
						}
					}
				}
			}
			placements = newPlacements;
			// TODO Auto Generated method stub
			presets.textureIndex = brushSizes.selectedIndex;
			presets.columns = columns.value;
			presets.rows = rows.value;
			presets.padding = padding.value;
			presets.allowUpscale = allowUpscale.selected;
			updateBrush();
			
			
			for ( row = 0; row < presets.rows ; row++ )
			{
				for (  col = 0; col < presets.columns ; col++ )
				{
					if ( placements[row][col] != null )
					{
						var map:Bitmap = placements[row][col].map;
						map.scaleX = map.scaleY = 1;
						map.scaleX = map.scaleY = Math.min(( columnWidth - presets.padding * 2) / map.width, (rowHeight  - presets.padding * 2)/ map.height);
						if ( !presets.allowUpscale && map.scaleX > 1 ) map.scaleX = map.scaleY = 1;
						map.x = (col * columnWidth + columnWidth * 0.5 - map.width * 0.5) ;
						map.y = (row * rowHeight + rowHeight * 0.5  - map.height * 0.5);
				
					}
				}
			}
			
		}
		
		private function onPresetsChanged():void
		{
			// TODO Auto Generated method stub
			onImportFolderChanged(null);
			columns.value = presets.columns;
			rows.value = presets.rows;
			padding.value = presets.padding;
			brushSizes.selectedIndex = presets.textureIndex;
			backgroundColor.selectedIndex = presets.backgroundIndex;
			allowUpscale.selected = presets.allowUpscale;
			updateBrush();
		}
		
		private function updateBrush():void
		{
			if ( brushTexture ) brushTexture.dispose();
			brushTexture = new BitmapData(int(brushSizes.selectedItem),int(brushSizes.selectedItem),true,backgroundColor.selectedItem.value);
			brushTextureHolder.bitmapData = brushTexture;
			
			
			grid.graphics.clear();
			columnWidth = brushTexture.width / presets.columns;
			rowHeight = brushTexture.height / presets.rows;
			grid.graphics.lineStyle(0,0x808080,0.8);
			for ( var i:int = 1; i < presets.columns; i++ )
			{
				grid.graphics.moveTo(i*columnWidth,0);
				grid.graphics.lineTo(i*columnWidth,brushTexture.height);
				
			}
			for ( i = 1; i < presets.rows; i++ )
			{
				grid.graphics.moveTo(0,i*rowHeight);
				grid.graphics.lineTo(brushTexture.width,i*rowHeight);
				
			}
			var scale:Number = Math.min( stage.stageHeight - grid.y, stage.stageWidth  - grid.x ) / brushTexture.width;
			if ( scale > 1 ) scale = 1;
			if ( scale < 0.25 ) scale = 0.25;
			placementHolder.scaleX = placementHolder.scaleY = grid.scaleX = grid.scaleY = brushTextureHolder.scaleX = brushTextureHolder.scaleY = scale;
			
			
			
		}
		
		private function onSetImportFolder(event:Event ):void
		{
			var imagesFilter:FileFilter = new FileFilter("Images", "*.jpg;*.jpeg;*.png");
			presets.importFolder.browse([imagesFilter]);
			
		}
		
		protected function onImportFolderChanged(event:Event):void
		{
			var brushFiles:Vector.<File> = getAllFilesFromDir(  presets.importFolder.isDirectory ? presets.importFolder : presets.importFolder.parent,["png","jpg","jpeg"] );
			folderPreview.reset();
			for ( var i:int = 0; i < brushFiles.length; i++ )
			{
				var fs:FileStream = new FileStream();
				fs.open(brushFiles[i],"read");
				var data:ByteArray = new ByteArray();
				fs.readBytes(data);
				fs.close();
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded );
				loader.loadBytes(data);
			}
			
		}
		
		protected function onImageLoaded(event:Event):void
		{
			LoaderInfo(event.target).removeEventListener(Event.COMPLETE, onImageLoaded );
			folderPreview.addBitmap(Bitmap(LoaderInfo(event.target).content));
			folderPreview.redraw();
		}
		
		protected function onMouseDown( event:MouseEvent ):void
		{
			if ( folderPreview.hitTestPoint(event.stageX,event.stageY) )
			{
				var selection:Bitmap = folderPreview.getBitmapAtPoint(new Point(event.stageX,event.stageY));
				if ( selection != null )
				{
					selectedMap = selection.bitmapData.clone();
					dragBitmap.bitmapData = selectedMap;
					dragBitmap.smoothing = true;
					dragBitmap.scaleX = dragBitmap.scaleY = Math.min(( columnWidth - presets.padding * 2) / selectedMap.width, (rowHeight  - presets.padding * 2)/ selectedMap.height);
					if (!presets.allowUpscale && dragBitmap.scaleX > 1)
					{
						dragBitmap.scaleX = dragBitmap.scaleY = 1
					}
					dragBitmap.scaleX *= placementHolder.scaleX;
					dragBitmap.scaleY *= placementHolder.scaleY;
					
					if ( shiftIsPressed && setNextFreeCellIndices() )
					{
						dragBitmap.x = brushTextureHolder.x + (currentColumnIndex * columnWidth + columnWidth * 0.5 - dragBitmap.width * 0.5) * brushTextureHolder.scaleX;
						dragBitmap.y = brushTextureHolder.y + (currentRowIndex * rowHeight + rowHeight * 0.5  - dragBitmap.height * 0.5) * brushTextureHolder.scaleY;
						dragBitmap.visible = false;
						addSelectionToGrid();
					} else {
						dragBitmap.visible = true;
						stage.addEventListener( MouseEvent.MOUSE_MOVE, dragSelection );
						stage.addEventListener( MouseEvent.MOUSE_UP, stopDragSelection );
						dragSelection(null);
					}
				}
			} else {
				
				if ( event.stageX >= brushTextureHolder.x && event.stageY >= brushTextureHolder.y &&
					event.stageX < brushTextureHolder.x +  brushTextureHolder.width && event.stageY < brushTextureHolder.y + brushTextureHolder.height )
				{
					if ( currentGridSelection !=null )
					{
						currentGridSelection.transform.colorTransform =  new ColorTransform();
						currentGridSelection = null;
					}
					var result:Array = stage.getObjectsUnderPoint(new Point(event.stageX,event.stageY));
					for ( var i:int = 0; i < result.length; i++ )
					{
						
						if ( result[i] is Bitmap && result[i] != brushTextureHolder) 
						{
							currentGridSelection = result[i] as Bitmap;
							currentGridSelection.transform.colorTransform = new ColorTransform(1,1,1,1,80,0,0,128);
							break;
						}
					}
				} else {
					if ( event.stageY > 32 )
					{
						if ( currentGridSelection !=null )
						{
							currentGridSelection.transform.colorTransform =  new ColorTransform();
							currentGridSelection = null;
						}
					}
				}
				
			} 
			
		}
		
		protected function onMouseWheel(event:MouseEvent):void
		{
			if ( stage.mouseX < 300 && stage.mouseY > 32 ) folderPreview.moveColumnsBy(event.delta *5,0.9);
			
		}
		
		protected function setNextFreeCellIndices():Boolean
		{
			for ( var row:int = 0; row < presets.rows ; row++ )
			{
				for ( var col:int = 0; col < presets.columns ; col++ )
				{
					if ( placements[row][col] == null )
					{
						addDragBitmapToTexture = true;
						currentColumnIndex = col;
						currentRowIndex = row;
						return true
						break;
					}
				}
			}
			return false;
		}
		
		protected function stopDragSelection(event:MouseEvent):void
		{
			
			stage.removeEventListener( MouseEvent.MOUSE_MOVE, dragSelection );
			stage.removeEventListener( MouseEvent.MOUSE_UP, stopDragSelection );
			dragBitmap.visible = false;
			if ( addDragBitmapToTexture )
			{
				addSelectionToGrid();
				
			}
		}
		
		private function addSelectionToGrid():void
		{
			if ( placements[currentRowIndex][currentColumnIndex] == null )
			{
				placements[currentRowIndex][currentColumnIndex] = new BrushPlacementInfo();
				var holder:Bitmap = new Bitmap(dragBitmap.bitmapData,"auto",true);
				holder.scaleX = holder.scaleY = dragBitmap.scaleX / placementHolder.scaleX;
				holder.x = (dragBitmap.x - placementHolder.x) / placementHolder.scaleX;
				holder.y = (dragBitmap.y - placementHolder.y) / placementHolder.scaleX;
				placementHolder.addChild( holder);
				placements[currentRowIndex][currentColumnIndex].map = holder;
				placements[currentRowIndex][currentColumnIndex].scale = 1;
			} else {
				var gridInfo:BrushPlacementInfo = placements[currentRowIndex][currentColumnIndex];
				gridInfo.map.bitmapData = dragBitmap.bitmapData;
				gridInfo.map.smoothing = true;
				gridInfo.map.scaleX = gridInfo.map.scaleY = 1;
				gridInfo.map.scaleX = gridInfo.map.scaleY = Math.min(( columnWidth - presets.padding * 2) / gridInfo.map.width, (rowHeight  - presets.padding * 2)/ gridInfo.map.height) * gridInfo.scale;
				
				gridInfo.map.x = (currentColumnIndex * columnWidth + columnWidth * 0.5 - dragBitmap.width * 0.5);
				gridInfo.map.y = (currentRowIndex * rowHeight + rowHeight * 0.5  - dragBitmap.height * 0.5);
			}
			placements[currentRowIndex][currentColumnIndex].rotation = 0;
			
		}
		
		protected function dragSelection(event:MouseEvent):void
		{
			
			dragBitmap.x = stage.mouseX - dragBitmap.width * 0.5;
			dragBitmap.y = stage.mouseY - dragBitmap.height * 0.5;
			
			currentColumnIndex = ((stage.mouseX - brushTextureHolder.x) / brushTextureHolder.scaleX) / columnWidth;
			currentRowIndex = ((stage.mouseY - brushTextureHolder.y ) / brushTextureHolder.scaleY) / rowHeight;
			addDragBitmapToTexture = false;
			if ( currentColumnIndex >= 0 && currentRowIndex >= 0 && currentColumnIndex < presets.columns && currentRowIndex < presets.rows )
			{
				dragBitmap.x = brushTextureHolder.x + (currentColumnIndex * columnWidth + columnWidth * 0.5 - dragBitmap.width * 0.5) * brushTextureHolder.scaleX;
				dragBitmap.y = brushTextureHolder.y + (currentRowIndex * rowHeight + rowHeight * 0.5  - dragBitmap.height * 0.5) * brushTextureHolder.scaleY;
				addDragBitmapToTexture = true;
			}
			
		}	
		
		
		private function getAllFilesFromDir(STARTINGFILE:File, extensions:Array = null, INCSUB:Boolean = false):Vector.<File>
		{
			var arr:Vector.<File> = new Vector.<File>();
			
			for each(var lstFile:File in STARTINGFILE.getDirectoryListing())
			{
				if(lstFile.isDirectory && INCSUB)
				{
					for each(var subFile:File in getAllFilesFromDir(lstFile, extensions, true))
					{
						if ( extensions == null || extensions.indexOf(subFile.extension) > -1 ) arr.push(subFile);
					}
				}
				else
				{
					if ( extensions == null || extensions.indexOf(lstFile.extension) > -1 ) arr.push(lstFile);
				}
			}
			
			return arr;
		}
		
		private function saveTexture( event:Event ):void
		{
			if ( currentGridSelection !=null )
			{
				currentGridSelection.transform.colorTransform =  new ColorTransform();
				currentGridSelection = null;
			}
			
			
			brushTexture.drawWithQuality( placementHolder,null,null,"normal",null,true,StageQuality.HIGH_16X16_LINEAR );
			var data:ByteArray = new ByteArray();
			brushTexture.encode(brushTexture.rect, new PNGEncoderOptions(false), data );
			var saveFile:File = presets.importFolder.clone();
			saveFile.save( data,"BrushSet.png");
			updateBrush();
		}
	}
}