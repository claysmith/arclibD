/******************************************************************************* 

	Lighting code

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:     ArcLib team 
	
	Description:
	Lighting code
	
	Examples:
	--------------------
	--------------------

*******************************************************************************/

module arc.x.light.convexpolygon; 

import arc.math.point;

import derelict.opengl.gl;

import arc.x.light.edge; 

/// holds the vertices of a convex polygon
struct ConvexPolygon
{
	/// constructs from a vertex list, vertices must be in ccw order
	static ConvexPolygon fromVertices(Point[] verts)
	{
		assert(verts.length >= 3, "Polygon needs at least 3 vertices");
		
		ConvexPolygon poly;
		for(size_t i = 1; i < verts.length; ++i)
			poly.edges ~= Edge(verts[i-1], verts[i]);
		poly.edges ~= Edge(verts[$-1], verts[0]);
		
		assert(poly.isValid());
		return poly;
	}
	
	/// edges, in ccw order
	Edge[] edges;

	/***
		Finds the edges that face away from a given location 'from'.

		Returns:
			A list of indices into 'edges'. In ccw order.
	*/
	size_t[] getBackfacingEdgeIndices(ref Point from)
	{
		assert(isValid());
		
		size_t[] result;
		
		// find the indices of the two edges that face away from 'from' and that
		// have one adjacent edge facing towards 'from'
		size_t firstbackfacing = size_t.max, lastbackfacing = size_t.max;
		
		{			
			bool prev_edge_front, cur_edge_front;
			foreach(i, ref edge; edges)
			{
				if(edge.normal.dot(from - edge.from) < 0)
					cur_edge_front = true;
				else
					cur_edge_front = false;
				
				if(i != 0)
				{
					if(cur_edge_front && !prev_edge_front)
						firstbackfacing = i;
					else if(!cur_edge_front && prev_edge_front)
						lastbackfacing = i-1;
				}
				
				prev_edge_front = cur_edge_front;
			}
		}
		
		// if no change between front and backfacing vertices was found,
		// we are inside the polygon, consequently all edges face backwards
		if(firstbackfacing == size_t.max && lastbackfacing == size_t.max)
		{
			for(size_t i = 0; i < edges.length; ++i)
				result ~= i;
			return result;
		}
		// else, if one one of the changes was found, we missed the one at 0
		else if(firstbackfacing == size_t.max)
			firstbackfacing = 0;
		else if(lastbackfacing == size_t.max)
			lastbackfacing = edges.length - 1;
		
		// if this is true, we can just put the indices in result in order
		if(firstbackfacing <= lastbackfacing)
		{
			for(size_t i = firstbackfacing; i <= lastbackfacing; ++i)
				result ~= i;
		}
		// else we must go from first to $ and from 0 to last
		else
		{
			for(size_t i = firstbackfacing; i < edges.length; ++i)
				result ~= i;
			for(size_t i = 0; i <= lastbackfacing; ++i)
				result ~= i;
		}
		
		return result;
	}
	
	/// returns true if the edges list makes up a convex polygon and are in ccw order
	bool isValid()
	{
		for(size_t i = 0; i < edges.length; ++i)
		{
			size_t nexti = i+1 < edges.length ? i+1 : 0;
			if(edges[i].to != edges[nexti].from)
				return false;
			if(edges[i].tangent().cross(edges[nexti].tangent()) <= 0)
				return false;
		}
		
		return true;
	}
}