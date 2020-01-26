/******************************************************************************* 

	Turn a class into a singleton with this mixin

	Authors:       ArcLib team, see AUTHORS file 
	Maintainer:    Clay Smith (clayasaurus at gmail dot com) 
	License:       zlib/libpng license: $(LICENSE) 
	Copyright:      ArcLib team 

	Description:    
		Turn a class into a singleton with this mixin

	Examples:      
	---------------------
	---------------------

*******************************************************************************/

module arc.templates.singleton;

///
template SingletonMix() 
{
	///
	static typeof(this) singletonInstance;

	///
	this() 
	{
		assert (singletonInstance is null);
		singletonInstance = this;
	}

	///
	static typeof(this) getInstance() 
	{
		if (typeof(this).singletonInstance is null) 
		{
			new typeof(this);
			assert (typeof(this).singletonInstance !is null);

			static if (is(typeof(typeof(this).singletonInstance.initialize))) 
			{
				typeof(this).singletonInstance.initialize();
			}
		}
		return typeof(this).singletonInstance;
	}

}