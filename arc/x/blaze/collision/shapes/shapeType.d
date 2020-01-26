module arc.x.blaze.collision.shapes.shapeType;

// Note: not put in shape.d due to 'forward reference' errors in contactFactory

/** The various collision shape types supported by Blaze. */
enum ShapeType
{
	UNKNOWN = -1,
	CIRCLE,
	POLYGON,
	FLUID,
	SHAPE_COUNT
}
