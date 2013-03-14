package
{
	import com.quasimondo.geom.Vector2;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;

	final public class BrushSetCreatorPreset
	{
		
		
		private var callbackObject:Object;
		private var onParametersChanged:Function;
		public var importFolder:File;
		public var textureIndex:int;
		public var columns:int;
		public var rows:int;
		public var padding:int;
		public var backgroundIndex:int;
		public var allowUpscale:Boolean;
		
		public function BrushSetCreatorPreset( callbackObject:Object, onParametersChanged:Function  )
		{
			setCallbacks(callbackObject, onParametersChanged);
			init();
		}
		
		public function setCallbacks(callbackObject:Object, onParametersChanged:Function):void
		{
			this.callbackObject = callbackObject;
			this.onParametersChanged = onParametersChanged;
		}
		
		private function init():void
		{
			importFolder = File.desktopDirectory;;
			textureIndex = 4;
			columns = 4;
			rows = 4;
			padding = 2;
			backgroundIndex = 0;
			allowUpscale = false;
		}
		
		public function toFile( file:File ):void
		{
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.WRITE);
			
			fileStream.writeUTF( "BSC" );
			
			
			fileStream.writeUTF(importFolder.url);
			fileStream.writeUnsignedInt(textureIndex);
			fileStream.writeUnsignedInt(columns);
			fileStream.writeUnsignedInt(rows);
			fileStream.writeUnsignedInt(padding);
			fileStream.writeUnsignedInt(backgroundIndex);
			fileStream.writeBoolean(allowUpscale);
			fileStream.close();
		}
		
		public function fromFile( file:File):void
		{
			var fileStream:FileStream = new FileStream();
			fileStream.open(file, FileMode.READ);
			try
			{
			
				var id:String = fileStream.readUTF();
				if ( id != "BSC" ) return;
				
				importFolder.resolvePath(fileStream.readUTF());
				textureIndex = fileStream.readUnsignedInt();
				columns = fileStream.readUnsignedInt();
				rows = fileStream.readUnsignedInt();
				padding = fileStream.readUnsignedInt();
				backgroundIndex = fileStream.readUnsignedInt();
				allowUpscale = fileStream.readBoolean();
			} catch ( error:Error )
			{
				trace(error.toString());
			}
			fileStream.close();
			if ( onParametersChanged != null ) onParametersChanged.apply( callbackObject );
		}
	}
}