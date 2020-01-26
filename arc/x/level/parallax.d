/*******************************************************************************

	TileMap draws a tile-based map to the screen.

	Authors:        ArcLib team, see AUTHORS file
	Maintainer:     Brian Schott (briancschott at gmail dot com)
	License:        zlib/libpng license: $(LICENSE)
	Copyright:      ArcLib team

	Description:
		Code for drawing parallax backgrounds.

		Important note: Do not place any parallax drawing calls inside of
		camera.open() and camera.close() when using the arc.x.camera extension!
		Parallax does it's own transformations of the OpenGL coordinates that
		are not compatable with the camera.

	Examples:
	--------------------
// Create the new parallax background
auto parallax = new Parallax;

// Add a new layer to the background and store the layer index of the newly
// added layer for later use.
auto layerIndex = parallax.addLayer("background.png");

// Configure the background's scrolling behavior. This background layer will
// scroll vertically, but not horizontally.
parallax.setScrollOptions(layerIndex, false, 0.0, true 0.5);

// Add another layer
index = parallax.addLayer("background2.png");

// Set the background to scroll horizontally and vertically at a rate half
// that of the screen movement
parallax.setScrollOptions(index, true, 0.5, true, 0.5);

// Set the background to repeat horizontally and vertically
parallax.setRepeatOptions(indox, true, true);

// coordinates of the top left corner of the screen
int x = 0;
int y = 0;

// Draw all the layers to the screen
parallax.drawAllLayers(x, y);
	--------------------

*******************************************************************************/

module arc.x.level.parallax;

private import arc.types,
               arc.texture,
               arc.window,
			   arc.draw.image;

private import derelict.opengl.gl;

/**
 * Class for drawing parallax backgrounds.
 * See_Also: en.wikipedia.org/wiki/Parallax
 */
public class Parallax
{
	public:
		/**
		 * Adds a layer to the background
		 * Params:
		 *     fileName = the path to the image file
		 *     index = the index of the layer to add. If ommitted, the layer
		 *         will just be appended to the top of the drawing stack.
		 * Returns: the index of the newly added layer. (This is more useful
		 *     when index is not specified...)
		 */
		uint addLayer(char[] fileName, int index = -1)
		{
			ParallaxLayer layer = ParallaxLayer();
			layer.texture = Texture(fileName);
			if(index == -1)
			{
				m_layers ~= layer;
				return m_layers.length - 1;
			}
			else
			{
				m_layers.length = max(m_layers.length, index + 1);
				m_layers[index] = layer;
				return index;
			}
		}

		/**
		 * Configures the scrolling behavior of a layer
		 * Params:
		 *     layer = The index of the layer to configure
		 *     scrollHorizontal = true if the background layer scrolls
		 *         horizontally
		 *     horizontalScrollSpeed = the speed relative to the camera that the
		 *         background layer should move. 0.5 means half as fast, 1.0
		 *         will keep synchronized with the camera, and 2.0 would move
		 *         twice as fast
		 *     scrollVertical = true if the background layer scrolls vertically
		 *     verticalScrollSpeed = see horizontalScrollSpeed
		 */
		void setScrollOptions(size_t layer, bool scrollHorizontal,
			arcfl horizontalScrollSpeed, bool scrollVertical,
			arcfl verticalScrollSpeed)
		in
		{
			assert(layer < m_layers.length);
		}
		body
		{
			m_layers[layer].scrollHSpeed = horizontalScrollSpeed;
			m_layers[layer].scrollVSpeed = verticalScrollSpeed;
			m_layers[layer].scrollV = scrollVertical;
			m_layers[layer].scrollH = scrollHorizontal;
		}

		/**
		 * Sets the repeat behavior of a layer.
		 * Params:
		 *     layer = the index of the layer to configure
		 *     repeatHorizontal = true to make the background layer repeat
		 *         horizontally
		 *     repeatVertical = true to make the background layer repeat
		 *         vertically
		 */
		void setRepeatOptions(size_t layer, bool repeatHorizontal,
			bool repeatVertical)
		in
		{
			assert(layer < m_layers.length);
		}
		body
		{
			m_layers[layer].repeatH = repeatHorizontal;
			m_layers[layer].repeatV = repeatVertical;
		}

		/**
		 * Draws the specified layer to the screen
		 * Note:
		 *     Do not place this inside calls to camera.open() and
		 *     camera.close() when using the arc.x.camera extension.
		 * Params:
		 *     layer = the index of the layer to draw
		 *     x = the x-coordinate of the camera
		 *     y = the y-coordinate of the camera
		 */
		void drawLayer(size_t layer, int x, int y)
		in
		{
			assert(layer < m_layers.length);
		}
		body
		{
			m_drawLayer(m_layers[layer], x, y);
		}

		/**
		 * Draws all the parallax layers to the screen in order.
		 * Note:
		 *     Do not place this inside calls to camera.open() and
		 *     camera.close() when using the arc.x.camera extension.
		 * Params:
		 *     x = the x-coordinate of the camera
		 *     y = the y-coordinate of the camera
		 */
		void drawAllLayers(int x, int y)
		{
			foreach(layer; m_layers)
				m_drawLayer(layer, x, y);
		}

		/**
		 * Sets the new background color.
		 * Params:
		 *     c = the new background color
		 */
		void setBackgroundColor(Color c)
		{
			float rf = cast(float)c.r / 255.0f;
			float gf = cast(float)c.g / 255.0f;
			float bf = cast(float)c.b / 255.0f;
			glClearColor(rf, gf, bf, 1.0);
		}

		/**
		 * Checks if a layer is visible
		 * Params:
		 *     layer = The layer index that will be checked
		 * Returns: true if the layer is visible, false if not
		 */
		bool getLayerVisibility(size_t layer)
		in
		{
			assert(layer < m_layers.length);
		}
		body
		{
			return m_layers[layer].visible;
		}

		/**
		 * Sets the visibility of a parallax layer
		 * Params:
		 *     layer = The layer index that will be set
		 *     visible = true to set the layer visible, false to hide it
		 */
		void setLayerVisibility(size_t layer, bool visible)
		in
		{
			assert(layer < m_layers.length);
		}
		body
		{
			m_layers[layer].visible = true;
		}

		/**
		 * Returns: the number of layers in the background
		 */
		uint getLayerCount()
		{
			return m_layers.length;
		}

	private:

		// Storage for parallax layer information
		struct ParallaxLayer
		{
			// Image storage
			Texture texture;
			// Does the parallax tile horizontally?
			bool repeatH = false;
			// Does the parallax tile vertically?
			bool repeatV = false;
			// Does the parallax scroll horizontally?
			bool scrollH = false;
			// Does the parallax scroll horizontally?
			bool scrollV = false;
			// Horizontal scroll rate
			arcfl scrollHSpeed = 1.0;
			// Vertical scroll rate
			arcfl scrollVSpeed = 1.0;
			// Is the layer visible?
			bool visible = true;
		}

		// Actually do the drawing here
		void m_drawLayer(ref ParallaxLayer layer, int x, int y)
		{
			if(layer.visible == false)
				return;

			// number of times to repeat the layer
			uint xTimes = 0, yTimes = 0;

			int layerWidth = cast(int)(layer.texture.getSize().getWidth());
			int layerHeight = cast(int)(layer.texture.getSize().getHeight());

			calcBaseTimes(x, layer.scrollH, layer.scrollHSpeed, layer.repeatH,
				layerWidth, arc.window.getWidth(), x, xTimes);

			calcBaseTimes(y, layer.scrollV, layer.scrollVSpeed, layer.repeatV,
				layerHeight, arc.window.getHeight(), y, yTimes);

			// magic code to get the coordinates right...
			for(uint i = 0; i != xTimes; ++i)
			{
				int dstX = 0;
				if(x <= 0)
					dstX = x + (layerWidth * i);
				else
					if(arc.window.getWidth() > layerWidth)
						dstX = x + (layerWidth * -(i - 1));
					else
						dstX = x + (layerWidth * -i);
				for(uint j = 0; j != yTimes; ++j)
				{
					int dstY = 0;
					if(y <= 0)
						dstY = y + (layerHeight * j);
					else
					{
						if(arc.window.getHeight() > layerHeight)
							dstY = y + (layerHeight * -(j - 1));
						else
							dstY = y + (layerHeight * -j);
					}

					arc.draw.image.drawImageTopLeft(layer.texture,
						Point(dstX, dstY));
				}
			}
		}

		/**
		 * Calculates the starting coordinate for a background layer and the
		 * number of times that it should repeat.
		 * Params:
		 *     coord = the camera coordinate for the given axis in pixels
		 *     scroll = whether or not the background scrolls along this axis
		 *     scrollSpeed = the rate at which the background scrolls on this
		 *         axis.
		 *     tile = whether or not the background should repeat along the axis
		 *     dimention = the width or height of the layer in pixels
		 *     viewdimention = the width or height of the screen in pixels
		 * Returns:
		 *     rcoord = the resulting start coordinate for the background layer
		 *         in pixels
		 *     times = the number of times that the background should be
		 *         repeated along the axis
		 */
		void calcBaseTimes(int coord, bool scroll, arcfl scrollSpeed,
			bool tile, uint dimention, uint viewDimention, out int rcoord,
			out uint times)
		out
		{
			// We have to draw the thing at least once
			assert(times > 0);
		}
		body
		{
			if(scroll == true)
				rcoord = cast(int)(coord * scrollSpeed);
			else
				rcoord = 0;

			if(tile == true)
			{
				if(coord > 0)
					rcoord = -(rcoord % dimention);
				else
					rcoord = (-rcoord) % dimention;
				times = (viewDimention / dimention) + 2;
			}
			else
			{
				rcoord *= -1;
				times = 1;
			}
		}

		// Storage for the layers
		ParallaxLayer[] m_layers;
}
