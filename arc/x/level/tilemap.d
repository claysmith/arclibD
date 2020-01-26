/*******************************************************************************

	TileMap draws a tile-based map to the screen.

	Authors:        ArcLib team, see AUTHORS file
	Maintainer:     Brian Schott (briancschott at gmail dot com)
	License:        zlib/libpng license: $(LICENSE)
	Copyright:      ArcLib team

	Description:
		Code for drawing a tile-based map.

		Compiling with -debug=graphics will enable graphical debugging of the
		tile map code. See comments below.

	Examples:
	--------------------
import arc.all;
import arc.x.level.tilemap;
import arc.x.camera.camera;

void main()
{
	arc.window.open("tilemap test", 640, 480, false);
	arc.input.open();

	auto cam = new camera();
	auto map = new Tilemap(25, 20, 1, 32);
	auto tileIndex = map.addTileSet("path/to/tiles.png");

	for(int x = 0, x != 25; ++x)
	{
		for(int y = 0; y != 20; ++y)
		{
			map.addTile(x, y, 0, x, y, tileIndex);
		}
	}

	while(!arc.input.keyDown(arc.input.ARC_QUIT))
	{
		arc.time.process();
		arc.input.process();
		cam.process();

		cam.open();
		auto p = cam.getPosition();
		map.drawAllLayers(cast(int)p.x, cast(int)p.y);
		cam.close();

		arc.window.swap();
		arc.time.limitFPS(60);
	}
}
	--------------------

*******************************************************************************/

module arc.x.level.tilemap;

private import arc.types,
               arc.window,
			   arc.texture,
			   arc.draw.image;

private import derelict.opengl.gl;

import tango.io.Console;
import tango.stdc.stdio;

/**
 * TileMap draws tile-based maps to the screen.
 *
 * Coordinates:
 * The coordinate system for TileMap places (0, 0) on the top left, with
 * increasing x-coordinates extending to the right, and increasing y-coordinates
 * extending down.
 *
 * Layers:
 * Higher layer indicies indicate layers that are placed on top. Index 0 will be
 * placed on the bottom with successive layers drawn on top.
 */
public class TileMap
{
	public:
		/**
		 * Params:
		 *     width = the width of the map in tiles
		 *     height = the height of the map in tiles
		 */
		this(uint width, uint height, uint layers, uint tileSize)
		{
			m_tiles = new Tile*[][][](layers, width, height);

			debug(all)
			{
				assert(getWidth() == width);
				assert(getHeight() == height);
				assert(getLayerCount() == layers);
			}

			m_visibilities = new bool[](layers);
			foreach(ref vis; m_visibilities)
				vis = true;
			m_tileSize = tileSize;
		}

		/**
		 * Currently does nothing.
		 */
		~this()
		{
		}

		/**
		 * Draws a layer of the map to the screen
		 * Params:
		 *     layer = the layer to draw
		 *     x = the x-coordinate (in pixels) of the center of the screen
		 *     y = the y-coordinate (in pixels) of the center of the screen
		 */
		void drawLayer(size_t layer, int x, int y)
		{
			if(m_visibilities[layer] == false)
				return;

			void calcStartEnd(int a, ref int oldA, ref size_t start,
				ref size_t end, size_t dimention, int screenDimention)
			{
				if(a != oldA)
				{
					// The casting here is to get meaningful comparisons to 0.
					int windowTileSize = screenDimention / m_tileSize;
					start = a < 0 ? 0 : cast(size_t)(a / cast(int)m_tileSize);
					end = min(max(windowTileSize + start + 1, 0), dimention);
					if(a < 1)
					{
						end = max(0, cast(int)(end) + (a
							/ cast(int)m_tileSize));
					}
					oldA = a;
				}
			}

			calcStartEnd(x, oldX, startX, endX, getWidth(),
				arc.window.getWidth());
			calcStartEnd(y, oldY, startY, endY, getHeight(),
				arc.window.getHeight());

			for(size_t i = startX; i < endX; ++i)
			{
				for(size_t j = startY; j < endY; ++j)
				{
					drawTile(layer, i, j);
					debug(graphics)
					{
						// Displays every cell in the map
						// Empty cells in red, filled in green.
						glMatrixMode(GL_MODELVIEW);
						glPushMatrix();
						glTranslatef(i * m_tileSize, j * m_tileSize, 0.0);
						glDisable(GL_TEXTURE_2D);

						// Outline
						if(m_tiles[layer][i][j] == null)
							glColor4f(1.0, 0.0, 0.0, 1.0);
						else
							glColor4f(0.0, 1.0, 0.0, 1.0);
						glBegin(GL_LINE_LOOP);
						glVertex2f(0, 0);
						glVertex2f(m_tileSize, 0);
						glVertex2f(m_tileSize, m_tileSize);
						glVertex2f(0, m_tileSize);
						glEnd();

						// Transparent fill
						if(m_tiles[layer][i][j] == null)
							glColor4f(1.0, 0.0, 0.0, 0.1);
						else
							glColor4f(0.0, 1.0, 0.0, 0.1);
						glBegin(GL_QUADS);
						glVertex2f(0, 0);
						glVertex2f(m_tileSize, 0);
						glVertex2f(m_tileSize, m_tileSize);
						glVertex2f(0, m_tileSize);
						glEnd();

						glEnable(GL_TEXTURE_2D);
						glPopMatrix();
					}
				}
			}

			debug(graphics)
			{
				// Show the extents of the map in blue.
				glDisable(GL_TEXTURE_2D);
				glColor4f(0.0, 0.0, 1.0, 1.0);
				glBegin(GL_LINE_LOOP);
				glVertex2f(0, 0);
				glVertex2f(getPixelWidth(), 0);
				glVertex2f(getPixelWidth(), getPixelHeight());
				glVertex2f(0, getPixelHeight());
				glEnd();
				glEnable(GL_TEXTURE_2D);
			}
		}



		/**
		 * Draws all the layers of the map.
		 * See_Also: drawLayer
		 * Params:
		 *     x = the x-coordinate (in pixels) of the left
		 *     y = the y-coordinate (in pixels) of the top
		 */
		void drawAllLayers(int x, int y)
		{
			for(size_t z = 0; z != getLayerCount(); ++z)
			{
				if(m_visibilities[z] == true)
				{
					drawLayer(z, x, y);
				}
			}
		}

		/**
		 * Checks if a layer is visible
		 * Params:
		 *     layer = The layer index that will be checked
		 * Returns: true if the layer is visible, false if not
		 */
		bool getLayerVisibility(size_t layer)
		{
			if(layer + 1 <= m_visibilities.length)
				return m_visibilities[layer];
			else
				return false;
		}

		/**
		 * Sets the visibility of a layer of the map
		 * Params:
		 *     layer = The layer index that will be set
		 *     visible = true to set the layer visible, false to hide it
		 */
		void setLayerVisibility(size_t layer, bool visible)
		in
		{
			assert(layer < m_tiles.length);
		}
		body
		{
			m_visibilities[layer] = visible;
		}

		/**
		 * Brief description
		 * Params:
		 *     x = the x-coordinate of the tile
		 *     y = the y-coordinate of the tile
		 *     layer = the layer of the tile
		 *     visible = the new visibility of the tile
		 */
		void setTileVisibility(size_t x, size_t y, size_t layer, bool visible)
		in
		{
			assert(x < getWidth());
			assert(y < getHeight());
			assert(layer < getLayerCount());
		}
		body
		{
			Tile* t = m_tiles[layer][x][y];
			if(visible)
				t.flags |= TILEFLAGS.VISIBLE;
			else
				t.flags ^= (t.flags & TILEFLAGS.VISIBLE);
		}

		/**
		 * Gets the visibility of a tile
		 * Params:
		 *     x = the x-coordinate of the tile
		 *     y = the y-coordinate of the tile
		 *     layer = the layer of the tile
		 * Returns: true if the tile is visible, false otherwise.
		 */
		bool getTileVisibility(size_t x, size_t y, size_t layer)
		in
		{
			assert(x < getWidth());
			assert(y < getHeight());
			assert(layer < getLayerCount());
		}
		body
		{
			return ((m_tiles[layer][x][y].flags & TILEFLAGS.VISIBLE) > 1);
		}

		void toggleTileVisibility(size_t x, size_t y, size_t layer)
		in
		{
			assert(x < getWidth());
			assert(y < getHeight());
			assert(layer < getLayerCount());
		}
		body
		{
			m_tiles[layer][x][y].flags ^= TILEFLAGS.VISIBLE;
		}


		/**
		 * Returns: the number of layers in the map. Will return 0 for a map
		 *     that has not yet been loaded
		 */
		size_t getLayerCount()
		{
			return m_tiles.length;
		}

		/**
		 * Returns: the width of the map in tiles
		 */
		size_t getWidth()
		{
			return m_tiles[0].length;
		}

		/**
		 * Returns: the height of the map in tiles
		 */
		size_t getHeight()
		{
			return m_tiles[0][0].length;
		}

		/**
		 * Returns: the width of a tile in pixels. The tiles are squares, so
		 *     this is also the height.
		 */
		uint getTileSize()
		{
			return m_tileSize;
		}

		/**
		 * Returns: the width of the map in pixels. This is a convenience
		 *     function equivalent to this.getWidth() * this.getTileSize()
		 */
		uint getPixelWidth()
		{
			return getTileSize() * getWidth();
		}

		/**
		 * Returns: the height of the map in pixels. This is a convenience
		 *     function equivalent to this.getHeight() * this.getTileSize()
		 */
		uint getPixelHeight()
		{
			return getTileSize() * getHeight();
		}

		/**
		 * Adds a tileset for use in the map. This must be a path to an image
		 * file that can be loaded by arc.texture
		 * Params:
		 *     fileName = the path to the image file
		 * Returns: the index of the newly added tileset.
		 * Throws: The exception from arc.texture.Texture.loadTexture is not
		 *     caught here.
		 */
		size_t addTileSet(char[] fileName, int index = -1)
		in
		{
			assert(index >= -1);
		}
		body
		{
			if(index == -1)
			{
				m_textures ~= arc.texture.Texture(fileName);
				return m_textures.length - 1;
			}
			else
			{
				m_textures.length = max(index + 1, m_textures.length);
				m_textures[index] = arc.texture.Texture(fileName);
				return index;
			}
		}

		/**
		 * Adds a tile to the map.
		 * Params:
		 *     x = the x-coordinate for the tile
		 *     y = the y-coordinate for the tile
		 *     layer = the layer for the tile
		 *     imageX = the x-coordinate of the image section to use
		 *     imageY = the y-coordinate of the image section to use
		 *     imageIndex = the image that the tile should use
		 */
		void addTile(uint x, uint y, size_t layer, uint imageX, uint imageY,
			size_t imageIndex)
		{
			if(x >= getWidth() || y >= getHeight() || layer >= getLayerCount())
				return;

			if(m_tiles[layer][x][y] == null)
			{
				m_tiles[layer][x][y] = new Tile;
			}

			m_tiles[layer][x][y].imageX = imageX;
			m_tiles[layer][x][y].imageY = imageY;
			m_tiles[layer][x][y].imageIndex = imageIndex;
			m_tiles[layer][x][y].flags |= TILEFLAGS.VISIBLE;
		}

		/**
		 * Removes a tile from the map
		 * Params:
		 *     x = the x-coordinate of the tile
		 *     y = the y-coordinate of the tile
		 *     layer = the layer of the tile
		 */
		 void removeTile(uint x, uint y, size_t layer)
		 {
			 delete m_tiles[layer][x][y];
			 m_tiles[layer][x][y] = null;
		 }

	private:

		enum TILEFLAGS
		{
			VISIBLE = 1
		}

		struct Tile
		{
			uint imageX = void;
			uint imageY = void;
			size_t imageIndex = void;
			byte flags = 1;
		}

		void drawTile(size_t layer, uint x, uint y)
		in
		{
			assert(x < getWidth());
			assert(y < getHeight());
			assert(layer < getLayerCount());
		}
		body
		{
			Tile* t = m_tiles[layer][x][y];
			if(t != null && (t.flags & TILEFLAGS.VISIBLE))
			{
				// Texture coordinates
				uint tx = t.imageX * m_tileSize;
				uint ty = t.imageY * m_tileSize;

				glMatrixMode(GL_MODELVIEW);
				glPushMatrix();
				glTranslatef(x * m_tileSize, y * m_tileSize, 0.0);
				drawImageSubsection(m_textures[t.imageIndex], Point(tx, ty),
					Point(tx + m_tileSize, ty + m_tileSize));
				glPopMatrix();
			}
		}

		// Storage for tiles
		// m_tiles[layer][x-index][y-index]
		Tile*[][][] m_tiles = void;

		// Size of tile in pixels
		uint m_tileSize = 0;

		// Layer visibilty storage
		bool m_visibilities[];

		// Texture storage
		Texture m_textures[];

		// Avoid unneeded calculations.
		size_t startX;
		size_t startY;
		size_t endX;
		size_t endY;
		int oldX = int.max;
		int oldY = int.max;
}
