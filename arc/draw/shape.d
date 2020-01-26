/******************************************************************************* 

	Drawing of different primitive shapes 

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 

	Description:    
		drawPixel, drawLine, drawCircle, drawRectangle, drawPolygon,
		drawRoundEdgeRect
		
		Different functions for drawing of primitive shapes. 

*******************************************************************************/

module arc.draw.shape; 

import 
	arc.types,
	arc.draw.color,
	arc.draw.attributes, 
	arc.math.angle,
	arc.math.point; 
	
import tango.math.Math; 

import derelict.opengl.gl; 

/// draw pixel at position and color
void drawPixel(Point pos, DrawAttributes attr)
{
	// disable gl textures
	glDisable(GL_TEXTURE_2D);

	// set color to one given
	attr.fill.setGLColor(); 

	// make sure the line width is only 1 pixel wide
	glLineWidth(1);

	// draw line
	glBegin(GL_LINE_LOOP);

	glVertex2f(pos.x, pos.y);
	glVertex2f(pos.x+1, pos.y); 

	glEnd();
}

/// draw line with color
void drawLine( Point pos1, Point pos2, DrawAttributes attr )
{
	// disable gl textures
	glDisable(GL_TEXTURE_2D);

	// set color to one given
	attr.stroke.setGLColor(); 
	
	glEnable(GL_LINE_SMOOTH);

	// draw line
	glBegin(GL_LINES);

	glVertex2f(pos1.x, pos1.y);
	glVertex2f(pos2.x, pos2.y); 

	glEnd();
}

/// draw circle at position, size (radius), detail (vertex's), and color
void drawCircle(Point pos, arcfl radius, DrawAttributes attr)
{
	// primitives can only be drawn once textures are disabled
	glDisable(GL_TEXTURE_2D); 

	// we will be drawing lines
	if (attr.isFill)
	{
		attr.fill.setGLColor();
		glBegin(GL_POLYGON);
	}
	else
	{		
		attr.stroke.setGLColor();
		glLineWidth(attr.strokeWidth);
		glEnable(GL_LINE_SMOOTH);
		glBegin(GL_LINE_LOOP);
	}

	arcfl px, py; 

	for (arcfl i = 0; i < 360; i+= 360.0/attr.detail)
	{
		// create polar coordinate
		px = radius;
		py = i; 

		// translate it to rectangular
		py = degreesToRadians(py); // convert degrees to radian
   
		arcfl x_save = px;
   
		px = x_save * cos(py); // i know, polar->y is used too much, but i'd like to eliminate the need
		py = x_save * sin(py); // for too many variables

		// and draw it
		glVertex2f(pos.x+px, pos.y+py);
	}
      
	glEnd(); 
}

/// draw circle at position, size (radius), detail (vertex's), and color
void drawEllipse(Point pos, Point radius, DrawAttributes attr)
{
	// primitives can only be drawn once textures are disabled
	glDisable(GL_TEXTURE_2D); 

	// we will be drawing lines
	if (attr.isFill)
	{
		attr.fill.setGLColor();
		glBegin(GL_POLYGON);
	}
	else
	{		
		attr.stroke.setGLColor();
		glLineWidth(attr.strokeWidth); 
		glEnable(GL_LINE_SMOOTH);
		glBegin(GL_LINE_LOOP);
	}

	for (arcfl i = 0; i < 360; i+= 360.0/attr.detail)
	{
		float degInRad = degreesToRadians(i); 
		glVertex2f(pos.x+cos(degInRad)*radius.x, pos.y+sin(degInRad)*radius.y); 
	}
      
	glEnd(); 
}

/// draw rectange with given position, size, and color
void drawRectangle(Point pos, Size size, DrawAttributes attr)
{
	// disable images
	glDisable(GL_TEXTURE_2D); 

	// set color to one given
	attr.fill.setGLColor(); 
	
	// we will be drawing lines
	if (attr.isFill)
	{
		attr.fill.setGLColor();
		glBegin(GL_POLYGON);
	}
	else
	{		
		attr.stroke.setGLColor();
		glLineWidth(attr.strokeWidth);
		glEnable(GL_LINE_SMOOTH);
		glBegin(GL_LINE_LOOP);
	}   

	// draw box to the screen
	glVertex2f(pos.x+size.w, pos.y); 
      
	glVertex2f(pos.x+size.w, pos.y+size.h);
      
	glVertex2f(pos.x, pos.y + size.h);
      
	glVertex2f(pos.x, pos.y);     
      
	glEnd(); 
}

/// draw rectange with given position, size, and color
void drawRoundEdgeRect(Point pos, Size size, DrawAttributes attr)
{
	// disable images
	glDisable(GL_TEXTURE_2D); 
	
	// we will be drawing lines
	if (attr.isFill)
	{
		attr.fill.setGLColor();
		glBegin(GL_POLYGON);
	}
	else
	{		
		attr.stroke.setGLColor();
		glLineWidth(attr.strokeWidth);
		glEnable(GL_LINE_SMOOTH);
		glBegin(GL_LINE_LOOP);
	}  

	// mult detail by 4
	int detail = attr.detail * 4;

	arcfl px, py; 
	
	Point start = Point(pos.x+(size.h/2), pos.y+(size.h/2));

	// first draw from 90-->180
	for (arcfl i = 90; i <= 270; i += 360.0/detail)
	{
		// create polar coordinate
		px = size.h/2;
		py = i; 

		// translate it to rectangular
		py = degreesToRadians(py); // convert degrees to radian
   
		arcfl x_save = px;
   
		px = x_save * cos(py); // i know, polar->y is used too much, but i'd like to eliminate the need
		py = x_save * sin(py); // for too many variables

		// and draw it
		glVertex2f(start.x+px, start.y+py);
	}

	// draw from top left --> right left 
	glVertex2f(pos.x+(size.h/2), pos.y); 
	glVertex2f(pos.x+size.w-(size.h/2), pos.y); 
	
	start = Point(pos.x+size.w-(size.h/2), pos.y+(size.h/2));
	
	// first draw from 270-->360
	for (arcfl i = 270; i <= 360; i += 360.0/detail)
	{
		// create polar coordinate
		px = size.h/2;
		py = i; 

		// translate it to rectangular
		py = degreesToRadians(py); // convert degrees to radian
   
		arcfl x_save = px;
   
		px = x_save * cos(py); // i know, polar->y is used too much, but i'd like to eliminate the need
		py = x_save * sin(py); // for too many variables

		// and draw it
		glVertex2f(start.x+px, start.y+py);
	}
	
	// first draw from 270-->360
	for (arcfl i = 0; i <= 90; i += 360.0/detail)
	{
		// create polar coordinate
		px = size.h/2;
		py = i; 

		// translate it to rectangular
		py = degreesToRadians(py); // convert degrees to radian
   
		arcfl x_save = px;
   
		px = x_save * cos(py); // i know, polar->y is used too much, but i'd like to eliminate the need
		py = x_save * sin(py); // for too many variables

		// and draw it
		glVertex2f(start.x+px, start.y+py);
	}

	// next draw top left corner
	glEnd(); 
}

/// draw polygon
void drawPolygon(Point pos, Point[] polygon, DrawAttributes attr)
{
	// disable images
	glDisable(GL_TEXTURE_2D); 
      
	// we will be drawing lines
	if (attr.isFill)
	{
		attr.fill.setGLColor();
		glBegin(GL_POLYGON);
	}
	else
	{		
		attr.stroke.setGLColor();
		glLineWidth(attr.strokeWidth);
		glEnable(GL_LINE_SMOOTH);
		glBegin(GL_LINE_LOOP);
	} 

	foreach(Point p; polygon)
		glVertex2f(pos.x + p.x, pos.y + p.y);
	
	glEnd(); 
}

/// draw polygon
void drawPolyLine(Point pos, Point[] polygon, DrawAttributes attr)
{
	// disable images
	glDisable(GL_TEXTURE_2D); 

	attr.stroke.setGLColor();
	glLineWidth(attr.strokeWidth);
	glEnable(GL_LINE_SMOOTH);
	glBegin(GL_LINES);

	foreach(Point p; polygon)
		glVertex2f(pos.x + p.x, pos.y + p.y);
	
	glEnd(); 
}