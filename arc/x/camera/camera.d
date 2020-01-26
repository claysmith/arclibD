/*******************************************************************************

    Camera module handles world transformation.

    Authors:       ArcLib team, see AUTHORS file
    Maintainer:    Clay Smith (clayasaurus at gmail dot com)
    License:       zlib/libpng license: $(LICENSE)
    Copyright:     ArcLib team

    Description:
        Camera class can handle multiple views of the same world
        by storing world position, size, zoom, and angle in the
        camera class.

        The Camera class functionality may soon be outdated by
        the scenegraph.

    Examples:
    ----------------------------------
        Camera c = new Camera;
		c.setProjection(0, arc.window.getWidth(), arc.window.getHight(), 0);
        c.setPosition(Point(x,y));

        c.process();
        c.open();
        // drawing code here
        c.close();
    ----------------------------------

*******************************************************************************/

module arc.x.camera.camera;

import arc.window;
import arc.math.point;
import arc.math.angle;
import arc.types;
import arc.input;

import derelict.opengl.gl;

/// Camera class, gives ability to move around the map/level/whatever
class Camera
{
  public:
	/// update camera-space mouse coordinates
	void process()
	{
		// transform mouse pos
		Point normalized_mouse = Point(arc.input.mouseX / arc.window.coordinates.getWidth, arc.input.mouseY / arc.window.coordinates.getHeight);
		mousePos = normalized_to_camera(normalized_mouse);

		// get view area
		viewPos = normalized_to_camera(Point(0,0));
		viewSize = normalized_to_camera(Point(1,1)) - viewPos;

		// set the projection to a sane default
		setProjection(0.0, arc.window.getWidth(), arc.window.getHeight(), 0.0);
	}

	/// add position to camera
	void move(Point v)
	{
		pos += v;
	}

	///
	void moveLeft(arcfl v=1)
	{
		pos.x -= v;
	}

	///
	void moveRight(arcfl v=1)
	{
		pos.x += v;
	}

	///
	void moveUp(arcfl v=1)
	{
		pos.y -= v;
	}

	///
	void moveDown(arcfl v=1)
	{
		pos.y += v;
	}

	/// set position of camera to point
	void setPosition(Point p)
	{
		pos = p;
	}

	/// get position of camera
	Point getPosition() { return pos; }

	/// get mouse position
	Point getMousePos() { return mousePos; }

	/// set zoom amount
	void setZoom(arcfl argZoom)
	{
		zoom = argZoom;
	}

	/// get zoom amount
	arcfl getZoom() { return zoom; }

	///
	void zoomIn(float val=1) { zoom-=val; }
	///
	void zoomOut(float val=1) {zoom+=val; }

	/// set angle amount
	void setAngle(Radians argAngle)
	{
		angle = argAngle;
	}

	/// get angle amount
	arcfl getAngle() { return angle; }

	/// Set GL projection settings with glOrtho
	void setProjection(arcfl argLeft, arcfl argRight, arcfl argBottom, arcfl argTop)
	{
		left = argLeft;
		right = argRight;
		bottom = argBottom;
		top = argTop;
	}

	/// start viewing transformations
	void open()
	{
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();

		arcfl width = right - left;
		arcfl height = bottom - top;
		arcfl mid_x = (left + right) / 2.;
		arcfl mid_y = (top + bottom) / 2.;
		glOrtho(mid_x - zoom * width / 2., mid_x + zoom * width / 2., mid_y + zoom * height / 2., mid_y - zoom * height / 2., -1.0f, 1.0f);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();

		glDisable(GL_DEPTH_TEST);
		glEnable(GL_TEXTURE_2D);

		glPushMatrix();

		// rotate
		//glRotatef(angle, 0,0,1);

		// translate to position (can be center of screen)
		glTranslatef(-pos.x, -pos.y, 0);
	}

	/// transforms a point
	Point camera_to_normalized(Point from)
	{
		Point extends = Point(right - left, bottom - top) * zoom;
		Point invextends = Point(1 / extends.x, 1 / extends.y);
		Point mid = Point((left + right) / 2., (top + bottom) / 2.);

		from -= pos;
		from.rotate(angle);
		from -= mid;
		from.scale(invextends);
		from += Point(0.5, 0.5);

		return from;
	}

	/// un-transforms a point
	Point normalized_to_camera(Point from)
	{
		Point extends = Point(right - left, bottom - top) * zoom;
		Point mid = Point((left + right) / 2., (top + bottom) / 2.);

		from -= Point(0.5, 0.5);
		from.scale(extends);
		from += mid;
		from.rotate(-angle);
		from += pos;

		return from;
	}

	/// end viewing transformations
	void close()
	{
		glPopMatrix();
	}

	/// get camera view position
	Point getViewPos()
	{
		return viewPos;
	}

	/// get camera viewing size
	Point getViewSize()
	{
		return viewSize;
	}

  private:
	Point pos = Point(0,0);
	arcfl zoom = 1;
	Radians angle = 0;
	arcfl left=0, right=0, bottom=0, top=0;

	// the mouse position in this camera's coordinate system, updated through process()
	Point mousePos;

	//BUG: Does not work with rotation
	// the lower left point of the view area
	Point viewPos;
	// the size of the view area
	Point viewSize;
}
